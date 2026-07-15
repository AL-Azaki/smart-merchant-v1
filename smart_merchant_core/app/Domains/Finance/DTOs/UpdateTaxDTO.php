<?php

namespace App\Domains\Finance\DTOs;

class UpdateTaxDTO
{
    public function __construct(
        public readonly string $taxId,
        public readonly string $businessId,
        public readonly string $taxName,
        public readonly float|string $taxRate
    ) {}
}
