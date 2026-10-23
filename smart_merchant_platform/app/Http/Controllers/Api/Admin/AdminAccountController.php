<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\Branch;
use App\Models\Business;
use App\Models\Currency;
use App\Models\Permission;
use App\Models\Plan;
use App\Models\Role;
use App\Models\Subscription;
use App\Models\SubscriptionInstallment;
use App\Models\SubscriptionPayment;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminAccountController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            // User fields (matching Flutter register_view.dart)
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'username' => 'required|string|max:50|unique:users,username',
            'email' => 'required|string|email|max:255|unique:users,email',
            'phone' => 'nullable|string|max:30',
            'password' => 'required|string|min:6',

            // Business fields (matching Flutter business_setup_view.dart)
            'business_name' => 'required|string|max:255',
            'business_type' => 'required|string|max:100',
            'primary_phone' => 'nullable|string|max:30',
            'primary_email' => 'nullable|email|max:255',
            'country' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'address' => 'nullable|string|max:255',
            'currency' => 'nullable|string|max:10',
        ]);

        return DB::transaction(function () use ($validated) {
            $fullName = trim($validated['first_name'] . ' ' . $validated['last_name']);

            // 1. Create Account (Immediately Active for Admin-provisioned accounts)
            $account = Account::create([
                'name' => $validated['business_name'] . ' Account',
                'owner_name' => $fullName,
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? $validated['primary_phone'] ?? null,
                'status' => 'Active',
            ]);

            // 2. Create Business
            $business = Business::create([
                'account_id' => $account->id,
                'business_name' => $validated['business_name'],
                'business_type' => $validated['business_type'],
                'primary_phone' => $validated['primary_phone'] ?? $validated['phone'] ?? null,
                'primary_email' => $validated['primary_email'] ?? $validated['email'] ?? null,
                'status' => 'Active',
            ]);

            // 3. Create Default Branch
            $branchAddress = $validated['address'] ?? ($validated['city'] ? $validated['city'] . ($validated['country'] ? ', ' . $validated['country'] : '') : null);
            $branch = Branch::create([
                'business_id' => $business->id,
                'branch_name' => 'الفرع الرئيسي',
                'branch_code' => 'MAIN',
                'address' => $branchAddress,
                'phone' => $validated['primary_phone'] ?? $validated['phone'] ?? null,
                'email' => $validated['primary_email'] ?? $validated['email'] ?? null,
                'is_default' => true,
                'is_active' => true,
            ]);

            // 4. Create User (Active)
            $user = User::create([
                'account_id' => $account->id,
                'full_name' => $fullName,
                'username' => $validated['username'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'password_hash' => Hash::make($validated['password']),
                'is_active' => true,
            ]);

            // 5. Connect User to Branch and set default branch
            $user->branches()->attach($branch->id);
            $user->update(['default_branch_id' => $branch->id]);

            // 6. Create Admin Role & assign permissions
            $role = Role::firstOrCreate([
                'business_id' => $business->id,
                'role_name' => 'Admin',
            ], [
                'description' => 'مدير النظام (Business Administrator)',
                'is_system_role' => true,
                'is_active' => true,
            ]);

            $permissions = Permission::all();
            if ($permissions->isNotEmpty()) {
                $role->permissions()->syncWithoutDetaching($permissions->pluck('id'));
            }
            $user->roles()->syncWithoutDetaching([$role->id]);

            // 7. Create Active Trial Subscription if plans exist
            $plan = Plan::where('is_active', true)->first();
            if ($plan) {
                Subscription::create([
                    'account_id' => $account->id,
                    'plan_id' => $plan->id,
                    'start_date' => now(),
                    'end_date' => now()->addMonths(1),
                    'amount_paid' => 0.00,
                    'status' => 'Active',
                ]);
            }

            return response()->json([
                'message' => 'تم إنشاء حساب العميل والنشاط التجاري بنجاح',
                'data' => [
                    'account' => $account->fresh()->loadCount(['businesses', 'users']),
                    'business' => $business,
                    'branch' => $branch,
                    'user' => [
                        'id' => $user->id,
                        'full_name' => $user->full_name,
                        'username' => $user->username,
                        'email' => $user->email,
                        'phone' => $user->phone,
                        'is_active' => $user->is_active,
                    ],
                    'credentials' => [
                        'email' => $user->email,
                        'password' => $validated['password'],
                    ],
                ],
            ], 201);
        });
    }
    public function index(Request $request)
    {
        $query = Account::withCount(['businesses', 'users']);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $search = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', $search)
                  ->orWhere('owner_name', 'like', $search)
                  ->orWhere('email', 'like', $search);
            });
        }

        $accounts = $query->latest()->paginate(20);

        return response()->json($accounts);
    }

    public function show(Request $request, string $id)
    {
        $account = Account::with(['businesses', 'users'])->findOrFail($id);

        return response()->json(['data' => $account]);
    }

    public function update(Request $request, string $id)
    {
        $account = Account::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:200',
            'owner_name' => 'sometimes|string|max:150',
            'phone' => 'nullable|string|max:30',
            'status' => ['sometimes', 'string', Rule::in(['Pending', 'Active', 'Suspended', 'Closed'])],
            'reason' => 'nullable|string|max:500',
        ]);

        $account->update(collect($validated)->only(['name', 'owner_name', 'phone', 'status'])->toArray());

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تم تحديث حالة الحساب بنجاح',
        ]);
    }

    public function approve(Request $request, string $id)
    {
        $account = Account::findOrFail($id);

        $validated = $request->validate([
            'plan_id' => 'nullable|uuid|exists:plans,id',
            'total_amount' => 'nullable|numeric|min:0',
            'down_payment' => 'nullable|numeric|min:0',
            'installment_frequency' => 'nullable|string|in:Monthly,Every2Months,Every3Months,Every4Months,SemiAnnual,Yearly,SinglePayment,Custom',
            'installments_count' => 'nullable|integer|min:1|max:60',
            'start_date' => 'nullable|date',
            'max_offline_days' => 'nullable|integer|min:1|max:90',
            'grace_period_days' => 'nullable|integer|min:0|max:30',
            'notes' => 'nullable|string|max:500',
            'custom_installments' => 'nullable|array',
            'custom_installments.*.installment_number' => 'required_with:custom_installments|integer',
            'custom_installments.*.due_date' => 'required_with:custom_installments|date',
            'custom_installments.*.amount' => 'required_with:custom_installments|numeric|min:0',
            'custom_installments.*.paid_amount' => 'nullable|numeric|min:0',
            'custom_installments.*.status' => 'nullable|string|in:Pending,Paid,PartiallyPaid',
            'custom_installments.*.notes' => 'nullable|string|max:255',
        ]);

        return DB::transaction(function () use ($account, $validated) {
            $account->update(['status' => 'Active']);

            // Find or default Plan
            $plan = null;
            if (!empty($validated['plan_id'])) {
                $plan = Plan::find($validated['plan_id']);
            }
            if (!$plan) {
                $plan = Plan::where('is_active', true)->first();
            }
            if (!$plan) {
                $currency = Currency::where('is_base_currency', true)->first() ?? Currency::first();
                if (!$currency) {
                    $currency = Currency::create([
                        'currency_code' => 'YER',
                        'currency_name_ar' => 'ريال يمني',
                        'currency_name_en' => 'Yemeni Rial',
                        'currency_symbol' => '﷼',
                        'decimal_places' => 2,
                        'exchange_rate' => 1.0,
                        'is_base_currency' => true,
                        'is_active' => true,
                    ]);
                }
                $plan = Plan::create([
                    'plan_name' => 'الخطة القياسية (Standard)',
                    'currency_id' => $currency->id,
                    'billing_cycle' => 'Yearly',
                    'duration_months' => 12,
                    'price' => 0.00,
                    'is_active' => true,
                ]);
            }

            $totalAmount = isset($validated['total_amount']) ? (float)$validated['total_amount'] : ($plan ? (float)$plan->price : 0.00);
            $downPayment = isset($validated['down_payment']) ? (float)$validated['down_payment'] : 0.00;
            $frequency = $validated['installment_frequency'] ?? 'Every3Months';
            $installmentsCount = isset($validated['installments_count']) ? (int)$validated['installments_count'] : 4;
            $startDate = !empty($validated['start_date']) ? Carbon::parse($validated['start_date']) : Carbon::now();
            $maxOfflineDays = isset($validated['max_offline_days']) ? (int)$validated['max_offline_days'] : 7;
            $gracePeriodDays = isset($validated['grace_period_days']) ? (int)$validated['grace_period_days'] : 3;

            // Generate or use custom installments schedule
            $leaseService = app(\App\Services\SubscriptionLeaseService::class);
            if (!empty($validated['custom_installments'])) {
                $schedule = $validated['custom_installments'];
            } else {
                $schedule = $leaseService->calculateInstallments(
                    $totalAmount,
                    $downPayment,
                    $frequency,
                    $installmentsCount,
                    $startDate
                );
            }

            // Determine subscription end date (last installment due date or +1 month/year)
            $lastInstallment = end($schedule);
            $endDate = !empty($lastInstallment['due_date'])
                ? Carbon::parse($lastInstallment['due_date'])->addMonths(1)
                : $startDate->copy()->addYear();

            $initialPaid = 0.00;
            foreach ($schedule as $inst) {
                if (($inst['status'] ?? '') === 'Paid') {
                    $initialPaid += (float)($inst['paid_amount'] ?? $inst['amount']);
                }
            }

            // Cancel any old active subscriptions
            $account->subscriptions()->where('status', 'Active')->update(['status' => 'Expired']);

            // Create subscription
            $subscription = Subscription::create([
                'account_id' => $account->id,
                'plan_id' => $plan ? $plan->id : null,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'total_amount' => $totalAmount,
                'amount_paid' => $initialPaid,
                'installments_count' => count($schedule),
                'installment_frequency' => $frequency,
                'status' => 'Active',
                'max_offline_days' => $maxOfflineDays,
                'grace_period_days' => $gracePeriodDays,
                'notes' => $validated['notes'] ?? null,
            ]);

            // Save installments
            $currency = Currency::where('is_base_currency', true)->first() ?? Currency::first();
            foreach ($schedule as $inst) {
                $installment = SubscriptionInstallment::create([
                    'subscription_id' => $subscription->id,
                    'account_id' => $account->id,
                    'installment_number' => $inst['installment_number'],
                    'due_date' => $inst['due_date'],
                    'amount' => $inst['amount'],
                    'paid_amount' => $inst['paid_amount'] ?? 0.00,
                    'status' => $inst['status'] ?? 'Pending',
                    'paid_at' => ($inst['status'] ?? '') === 'Paid' ? ($inst['paid_at'] ?? now()) : null,
                    'notes' => $inst['notes'] ?? null,
                ]);

                // If paid, record payment
                if (($inst['status'] ?? '') === 'Paid' && ($inst['paid_amount'] ?? $inst['amount']) > 0) {
                    SubscriptionPayment::create([
                        'subscription_id' => $subscription->id,
                        'account_id' => $account->id,
                        'currency_id' => $currency ? $currency->id : ($plan ? $plan->currency_id : null),
                        'receipt_number' => 'REC-' . strtoupper(uniqid()),
                        'payment_date' => now(),
                        'amount' => $inst['paid_amount'] ?? $inst['amount'],
                        'payment_method' => 'Cash',
                        'reference_number' => 'INIT-INSTALLMENT-' . $inst['installment_number'],
                        'status' => 'Paid',
                        'notes' => 'سداد الدفعة أو القسط رقم ' . $inst['installment_number'],
                    ]);
                }
            }

            // Send luxury branded approval notification email to merchant with installment schedule
            try {
                if ($account->email && filter_var($account->email, FILTER_VALIDATE_EMAIL)) {
                    \Illuminate\Support\Facades\Mail::to($account->email)->send(
                        new \App\Mail\AccountApprovedMail($account, $subscription)
                    );
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning("Failed to send approval email to {$account->email}: " . $e->getMessage());
            }

            return response()->json([
                'data' => $account->fresh()->loadCount(['businesses', 'users']),
                'subscription' => $subscription->fresh()->load(['installments', 'plan']),
                'message' => 'تم تفعيل الحساب وإنشاء خطة الأقساط وإرسال بريد التأكيد بنجاح',
            ]);
        });
    }

    public function statement(Request $request, string $id)
    {
        $account = Account::with(['businesses'])->findOrFail($id);

        $activeSubscription = $account->subscriptions()
            ->where('status', 'Active')
            ->with(['plan', 'installments', 'payments'])
            ->latest()
            ->first();

        $allSubscriptions = $account->subscriptions()
            ->with(['plan', 'installments', 'payments'])
            ->latest()
            ->get();

        $installments = $account->subscriptionInstallments()
            ->orderBy('due_date')
            ->get();

        return response()->json([
            'account' => $account,
            'active_subscription' => $activeSubscription,
            'all_subscriptions' => $allSubscriptions,
            'installments' => $installments,
        ]);
    }

    public function suspend(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'nullable|string|max:500',
        ]);

        $account = Account::findOrFail($id);
        $account->update(['status' => 'Suspended']);

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تم تعليق الحساب بنجاح',
        ]);
    }

    public function reactivate(Request $request, string $id)
    {
        $account = Account::findOrFail($id);
        $account->update(['status' => 'Active']);

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تمت إعادة تنشيط الحساب بنجاح',
        ]);
    }
}
