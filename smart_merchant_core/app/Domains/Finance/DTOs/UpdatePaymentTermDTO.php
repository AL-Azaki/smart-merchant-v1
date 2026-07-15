<?php

namespace App\Domains\Finance\DTOs;

class UpdatePaymentTermDTO
{
    public function __construct(
        public readonly string $paymentTermId,
        public readonly string $businessId,
        public readonly string $termName,
        public readonly int $daysToDue
    ) {}
}
