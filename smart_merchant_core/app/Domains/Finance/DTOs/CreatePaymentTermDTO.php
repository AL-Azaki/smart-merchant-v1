<?php

namespace App\Domains\Finance\DTOs;

class CreatePaymentTermDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $termName,
        public readonly int $daysToDue,
        public readonly bool $isActive = true
    ) {}
}
