<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Currency;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\SubscriptionInstallment;
use App\Models\SubscriptionPayment;
use App\Services\SubscriptionLeaseService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminSubscriptionController extends Controller
{
    /**
     * List all platform subscriptions with search, status filters, and financial metrics.
     */
    public function allSubscriptions(Request $request)
    {
        $query = Subscription::with(['account', 'plan', 'installments' => function ($q) {
            $q->orderBy('installment_number');
        }]);

        if ($request->filled('status') && $request->status !== 'All') {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $search = '%' . $request->search . '%';
            $query->whereHas('account', function ($q) use ($search) {
                $q->where('name', 'like', $search)
                  ->orWhere('owner_name', 'like', $search)
                  ->orWhere('email', 'like', $search)
                  ->orWhere('phone', 'like', $search);
            });
        }

        $subscriptions = $query->latest()->paginate($request->integer('per_page', 20));

        // High-level KPI metrics
        $metrics = [
            'total_subscriptions' => Subscription::count(),
            'active_subscriptions' => Subscription::where('status', 'Active')->count(),
            'expired_subscriptions' => Subscription::where('status', 'Expired')->count(),
            'total_revenue' => (float) Subscription::sum('amount_paid'),
            'total_contracted' => (float) Subscription::sum('total_amount'),
            'pending_installments_count' => SubscriptionInstallment::where('status', 'Pending')->count(),
            'overdue_installments_count' => SubscriptionInstallment::where('status', 'Pending')
                ->where('due_date', '<', now()->toDateString())
                ->count(),
        ];

        return response()->json([
            'metrics' => $metrics,
            'subscriptions' => $subscriptions,
        ]);
    }

    /**
     * Show single subscription with detailed installments & payments ledger.
     */
    public function showSubscription(Request $request, string $id)
    {
        $subscription = Subscription::with([
            'account.businesses',
            'plan',
            'installments' => function ($q) {
                $q->orderBy('installment_number');
            },
            'payments' => function ($q) {
                $q->latest();
            },
        ])->findOrFail($id);

        $leaseService = app(SubscriptionLeaseService::class);
        $lease = $leaseService->generateLeasePayload($subscription);

        return response()->json([
            'subscription' => $subscription,
            'lease' => $lease,
        ]);
    }

    /**
     * Record payment for a specific installment and automatically extend/reactivate the subscription lease.
     */
    public function payInstallment(Request $request, string $subscriptionId, string $installmentId)
    {
        $subscription = Subscription::findOrFail($subscriptionId);
        $installment = SubscriptionInstallment::where('subscription_id', $subscription->id)->findOrFail($installmentId);

        $validated = $request->validate([
            'amount' => 'nullable|numeric|min:0.01',
            'payment_method' => 'nullable|string|max:100',
            'reference_number' => 'nullable|string|max:100',
            'notes' => 'nullable|string|max:500',
        ]);

        return DB::transaction(function () use ($subscription, $installment, $validated) {
            $paymentAmount = isset($validated['amount']) ? (float)$validated['amount'] : (float)$installment->amount;
            $newPaidAmount = (float)$installment->paid_amount + $paymentAmount;
            $isFullyPaid = $newPaidAmount >= (float)$installment->amount;

            $installment->update([
                'paid_amount' => min($newPaidAmount, (float)$installment->amount),
                'status' => $isFullyPaid ? 'Paid' : 'PartiallyPaid',
                'paid_at' => now(),
                'payment_method' => $validated['payment_method'] ?? 'Cash',
                'transaction_reference' => $validated['reference_number'] ?? null,
                'notes' => $validated['notes'] ?? $installment->notes,
            ]);

            // Update parent subscription totals
            $subscription->increment('amount_paid', $paymentAmount);

            // If subscription was expired or suspended, reactivate it upon payment
            if ($subscription->status !== 'Active') {
                $subscription->update(['status' => 'Active']);
                $subscription->account->update(['status' => 'Active']);
            }

            // Find next installment to extend offline lease
            $nextDue = $subscription->fresh()->nextDueInstallment();
            if ($nextDue) {
                $subscription->update([
                    'offline_lease_valid_until' => Carbon::parse($nextDue->due_date)->endOfDay(),
                ]);
            }

            // Record in subscription_payments
            $currency = Currency::where('is_base_currency', true)->first() ?? Currency::first();
            $payment = SubscriptionPayment::create([
                'subscription_id' => $subscription->id,
                'account_id' => $subscription->account_id,
                'currency_id' => $currency ? $currency->id : ($subscription->plan ? $subscription->plan->currency_id : null),
                'receipt_number' => 'REC-' . strtoupper(uniqid()),
                'payment_date' => now(),
                'amount' => $paymentAmount,
                'payment_method' => $validated['payment_method'] ?? 'Cash',
                'reference_number' => $validated['reference_number'] ?? null,
                'status' => 'Paid',
                'notes' => 'سداد القسط رقم ' . $installment->installment_number . ($validated['notes'] ? ' - ' . $validated['notes'] : ''),
            ]);

            $leaseService = app(SubscriptionLeaseService::class);
            $lease = $leaseService->generateLeasePayload($subscription->fresh());

            return response()->json([
                'message' => 'تم تسجيل سداد القسط وتحديث حالة الاشتراك والرخصة الرقمية بنجاح',
                'installment' => $installment->fresh(),
                'subscription' => $subscription->fresh()->load(['installments', 'plan']),
                'payment' => $payment,
                'lease' => $lease,
            ]);
        });
    }

    /**
     * List all active subscription plans for dropdowns and contract creation.
     */
    public function plans(Request $request)
    {
        $plans = Plan::where('is_active', true)->with('currency')->get();
        return response()->json(['data' => $plans]);
    }

    // Legacy tenant scoped methods
    public function index(Request $request, Business $business)
    {
        $subscriptions = Subscription::where('account_id', $business->account_id)->with(['plan', 'installments'])->paginate(20);
        return response()->json($subscriptions);
    }

    public function show(Request $request, Business $business, Subscription $subscription)
    {
        if ($subscription->account_id !== $business->account_id) {
            abort(404);
        }
        
        $subscription->load(['plan', 'installments', 'payments']);
        return response()->json(['data' => $subscription]);
    }

    public function update(Request $request, Business $business, Subscription $subscription)
    {
        if ($subscription->account_id !== $business->account_id) {
            abort(404);
        }

        $validated = $request->validate([
            'status' => ['sometimes', 'string', Rule::in(['Active', 'Suspended', 'Expired'])],
            'max_offline_days' => 'nullable|integer|min:1|max:90',
            'grace_period_days' => 'nullable|integer|min:0|max:30',
        ]);

        $subscription->update($validated);

        return response()->json(['data' => $subscription->refresh()]);
    }
}
