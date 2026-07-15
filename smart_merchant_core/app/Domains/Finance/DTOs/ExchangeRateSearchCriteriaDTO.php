<?php

namespace App\Domains\Finance\DTOs;

class ExchangeRateSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $sourceCurrencyId = null,
        public readonly ?string $targetCurrencyId = null,
        public readonly ?string $effectiveDate = null,
        public readonly int $perPage = 15
    ) {}
}
