<?php

namespace App\Domains\Finance\DTOs;

class FiscalPeriodSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $fiscalYearId = null,
        public readonly ?string $name = null,
        public readonly ?string $status = null,
        public readonly int $perPage = 15
    ) {}
}
