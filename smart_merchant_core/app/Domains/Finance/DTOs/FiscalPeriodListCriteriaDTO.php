<?php

namespace App\Domains\Finance\DTOs;

class FiscalPeriodListCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $fiscalYearId,
        public readonly int $perPage = 15
    ) {}
}
