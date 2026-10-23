<?php

namespace App\Services;

use App\Models\Subscription;
use App\Models\SubscriptionInstallment;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class SubscriptionLeaseService
{
    /**
     * Generate an installment schedule array based on total, down payment, frequency, and count.
     */
    public function calculateInstallments(
        float $totalAmount,
        float $downPayment,
        string $frequency,
        int $installmentsCount,
        Carbon $startDate
    ): array {
        $schedule = [];
        $remainingTotal = max(0, $totalAmount - $downPayment);
        $currentDate = $startDate->copy();

        // 1. If there is a down payment, installment #1 is the down payment due on start date (or immediately paid)
        $installmentNumber = 1;
        if ($downPayment > 0) {
            $schedule[] = [
                'installment_number' => $installmentNumber++,
                'due_date' => $currentDate->toDateString(),
                'amount' => round($downPayment, 2),
                'paid_amount' => round($downPayment, 2),
                'status' => 'Paid',
                'paid_at' => now(),
                'notes' => 'الدفعة الأولى المقدمة (Down Payment)',
            ];
        }

        // 2. Divide remaining balance across the remaining installments
        $unpaidInstallmentsCount = $downPayment > 0 ? max(1, $installmentsCount - 1) : $installmentsCount;
        $baseInstallmentAmount = floor(($remainingTotal / $unpaidInstallmentsCount) * 100) / 100;
        $remainderCentAdjustment = round($remainingTotal - ($baseInstallmentAmount * $unpaidInstallmentsCount), 2);

        $monthsToAdd = match ($frequency) {
            'Monthly' => 1,
            'Every2Months' => 2,
            'Every3Months' => 3,
            'Every4Months' => 4,
            'SemiAnnual' => 6,
            'Yearly' => 12,
            default => 1,
        };

        for ($i = 0; $i < $unpaidInstallmentsCount; $i++) {
            $currentDate = $currentDate->copy()->addMonths($monthsToAdd);
            $amount = $baseInstallmentAmount;
            if ($i === 0 && $remainderCentAdjustment > 0) {
                $amount += $remainderCentAdjustment;
            }

            $installmentIndex = $i + 1;
            $schedule[] = [
                'installment_number' => $installmentNumber++,
                'due_date' => $currentDate->toDateString(),
                'amount' => round($amount, 2),
                'paid_amount' => 0.00,
                'status' => 'Pending',
                'paid_at' => null,
                'notes' => "القسط رقم {$installmentIndex} - دورة {$frequency}",
            ];
        }

        return $schedule;
    }

    /**
     * Generate a cryptographically signed Offline Lease Token for a subscription.
     */
    public function generateLeasePayload(Subscription $subscription, ?string $deviceUuid = null): array
    {
        $subscription->loadMissing(['account', 'plan', 'installments']);

        $nextInstallment = $subscription->nextDueInstallment();
        $now = Carbon::now();

        // The offline lease is valid until the next installment due date,
        // or subscription end date, whichever is earlier.
        // It also respects max_offline_days as a safety cap if required.
        $leaseExpiry = null;
        if ($nextInstallment) {
            $leaseExpiry = Carbon::parse($nextInstallment->due_date)->endOfDay();
        } elseif ($subscription->end_date) {
            $leaseExpiry = Carbon::parse($subscription->end_date)->endOfDay();
        } else {
            $leaseExpiry = $now->copy()->addDays($subscription->max_offline_days ?: 7);
        }

        // Grace period
        $graceDays = $subscription->grace_period_days ?? 3;
        $hardExpiry = $leaseExpiry->copy()->addDays($graceDays);

        $payload = [
            'lease_version' => '1.0',
            'subscription_id' => (string) $subscription->id,
            'account_id' => (string) $subscription->account_id,
            'plan_name' => $subscription->plan ? $subscription->plan->plan_name : 'Enterprise Plan',
            'device_uuid' => $deviceUuid,
            'status' => $subscription->status,
            'server_time' => $now->toIso8601String(),
            'server_timestamp' => $now->timestamp,
            'valid_from' => $now->toIso8601String(),
            'valid_until' => $leaseExpiry->toIso8601String(),
            'hard_expiry_with_grace' => $hardExpiry->toIso8601String(),
            'max_offline_days' => $subscription->max_offline_days ?? 7,
            'grace_period_days' => $graceDays,
            'next_installment' => $nextInstallment ? [
                'id' => (string) $nextInstallment->id,
                'installment_number' => $nextInstallment->installment_number,
                'due_date' => $nextInstallment->due_date ? Carbon::parse($nextInstallment->due_date)->toDateString() : null,
                'amount' => (float) $nextInstallment->amount,
            ] : null,
            'total_amount' => (float) $subscription->total_amount,
            'amount_paid' => (float) $subscription->amount_paid,
            'remaining_balance' => (float) $subscription->remaining_amount,
            'total_installments' => $subscription->installments->count(),
            'pending_installments' => $subscription->installments->where('status', '!=', 'Paid')->count(),
        ];

        // Sign payload with HMAC-SHA256 using APP_KEY
        $jsonPayload = json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        $signature = hash_hmac('sha256', $jsonPayload, config('app.key'));

        $signedToken = base64_encode(json_encode([
            'payload' => $payload,
            'signature' => $signature,
        ]));

        return [
            'payload' => $payload,
            'signed_token' => $signedToken,
        ];
    }
}
