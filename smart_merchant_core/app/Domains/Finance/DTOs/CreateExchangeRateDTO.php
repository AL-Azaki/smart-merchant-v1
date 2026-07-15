<?php

namespace App\Domains\Finance\DTOs;

class CreateExchangeRateDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $sourceCurrencyId,
        public readonly string $targetCurrencyId,
        public readonly string $effectiveDate,
        public readonly float|string $rate
    ) {}
}
