<?php

namespace App\Domains\Finance\DTOs;

class CreateTaxDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $taxName,
        public readonly float|string $taxRate,
        public readonly bool $isActive = true
    ) {}
}
