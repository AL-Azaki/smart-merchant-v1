<?php

namespace App\Domains\Core\DTOs;

class CreateSubscriptionDTO
{
    public function __construct(
        public readonly string $accountId,
        public readonly string $planId,
        public readonly string $currencyId,
        public readonly string $billingCycle, // 'monthly' or 'annual'
        public readonly ?string $trialEndsAt = null
    ) {}

    public static function fromRequest(array $data, string $accountId): self
    {
        return new self(
            accountId: $accountId,
            planId: $data['plan_id'],
            currencyId: $data['currency_id'],
            billingCycle: $data['billing_cycle'],
            trialEndsAt: $data['trial_ends_at'] ?? null
        );
    }
}
