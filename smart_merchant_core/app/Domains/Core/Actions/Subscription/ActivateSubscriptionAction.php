<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Domains\Core\Models\Subscription;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;
use Carbon\Carbon;

class ActivateSubscriptionAction
{
    public function __construct(
        private readonly SubscriptionRepositoryInterface $repository,
        private readonly SubscriptionPaymentRepositoryInterface $paymentRepository
    ) {}

    public function handle(string $subscriptionId, ?string $administrativeReason = null): Subscription
    {
        $subscription = $this->repository->findById($subscriptionId);

        if (!$subscription) {
            throw new CoreDomainException("The specified subscription does not exist.");
        }

        if ($subscription->status === 'Active') {
            return $subscription;
        }

        if ($subscription->status !== 'Pending' && $subscription->status !== 'Suspended') {
            throw new CoreDomainException("Cannot activate a subscription that is {$subscription->status}.");
        }

        if ($this->repository->hasActiveSubscription($subscription->account_id)) {
            throw new CoreDomainException("This account already has an Active subscription. Close it before activating a new one.");
        }

        if ($administrativeReason === null && !$this->paymentRepository->hasSuccessfulPayment($subscription->id)) {
            throw new CoreDomainException("Cannot activate subscription: No successful payment found and no administrative reason provided.");
        }

        // Calculate dates if not already set (e.g., from Pending -> Active)
        if ($subscription->starts_at === null) {
            $startsAt = Carbon::now();
            $endsAt = $subscription->billing_cycle === 'annual' 
                ? $startsAt->copy()->addYear() 
                : $startsAt->copy()->addMonth();

            $this->repository->updateDates($subscription, [
                'starts_at' => $startsAt,
                'ends_at'   => $endsAt,
            ]);
        }

        return $this->repository->updateStatus($subscription, 'Active');
    }
}
