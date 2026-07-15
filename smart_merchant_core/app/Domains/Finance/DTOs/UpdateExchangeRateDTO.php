<?php

namespace App\Domains\Finance\DTOs;

class UpdateExchangeRateDTO
{
    public function __construct(
        public readonly string $exchangeRateId,
        public readonly string $businessId,
        public readonly string $sourceCurrencyId,
        public readonly string $targetCurrencyId,
        public readonly string $effectiveDate,
        public readonly float|string $rate
    ) {}
}
