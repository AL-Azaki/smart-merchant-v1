<?php

namespace App\Domains\Core\DTOs;

class CreatePaymentIntentDTO
{
    public function __construct(
        public readonly string $subscriptionId,
        public readonly string $paymentMethod
    ) {}

    public static function fromRequest(array $data, string $subscriptionId): self
    {
        return new self(
            subscriptionId: $subscriptionId,
            paymentMethod: $data['payment_method']
        );
    }
}
