<?php

namespace App\Domains\Core\Actions\SubscriptionPayment;

use App\Domains\Core\Models\SubscriptionPayment;
use App\Domains\Core\DTOs\CreatePaymentIntentDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreatePaymentIntentAction
{
    public function __construct(
        private readonly SubscriptionPaymentRepositoryInterface $paymentRepository,
        private readonly SubscriptionRepositoryInterface $subscriptionRepository
    ) {}

    public function handle(CreatePaymentIntentDTO $dto): SubscriptionPayment
    {
        $subscription = $this->subscriptionRepository->findById($dto->subscriptionId);

        if (!$subscription) {
            throw new CoreDomainException("The specified subscription does not exist.");
        }

        if ($subscription->status !== 'Pending' && $subscription->status !== 'Suspended') {
            throw new CoreDomainException("Payments can only be initiated for Pending or Suspended subscriptions.");
        }

        // Snapshot details directly from the Subscription (Operational integrity)
        return $this->paymentRepository->create([
            'subscription_id' => $subscription->id,
            'amount'          => $subscription->price,
            'currency_code'   => $subscription->currency_code,
            'plan_name'       => $subscription->plan_name,
            'payment_method'  => $dto->paymentMethod,
            'status'          => 'Pending',
        ]);
    }
}
