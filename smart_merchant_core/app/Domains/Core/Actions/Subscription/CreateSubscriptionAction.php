<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Models\Core\Subscription;
use App\Domains\Core\DTOs\CreateSubscriptionDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateSubscriptionAction
{
    public function __construct(
        private readonly SubscriptionRepositoryInterface $subscriptionRepository,
        private readonly PlanRepositoryInterface $planRepository,
        private readonly CurrencyRepositoryInterface $currencyRepository
    ) {}

    public function handle(CreateSubscriptionDTO $dto): Subscription
    {
        $plan = $this->planRepository->findById($dto->planId);
        if (!$plan) {
            throw new CoreDomainException("The specified plan does not exist.");
        }
        if (!$plan->is_active) {
            throw new CoreDomainException("Cannot subscribe to an inactive plan.");
        }

        $currency = $this->currencyRepository->findById($dto->currencyId);
        if (!$currency) {
            throw new CoreDomainException("The specified currency does not exist.");
        }
        if (!$currency->is_active) {
            throw new CoreDomainException("Cannot use an inactive currency for a subscription.");
        }

        $price = $dto->billingCycle === 'annual' ? $plan->annual_price : $plan->monthly_price;

        // Snapshot of all required Reference Master Data
        return $this->subscriptionRepository->create([
            'account_id'     => $dto->accountId,
            'plan_id'        => $plan->id,
            'currency_id'    => $currency->id,
            'currency_code'  => $currency->code,
            'plan_name'      => $plan->name,
            'billing_cycle'  => $dto->billingCycle,
            'price'          => $price,
            'max_businesses' => $plan->max_businesses,
            'max_users'      => $plan->max_users,
            'features'       => $plan->features, // JSON casted in model
            'status'         => 'Pending', // Strictly Pending upon creation
            'trial_ends_at'  => $dto->trialEndsAt,
        ]);
    }
}
