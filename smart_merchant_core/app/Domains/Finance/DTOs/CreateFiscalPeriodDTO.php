<?php

namespace App\Domains\Finance\DTOs;

class CreateFiscalPeriodDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $fiscalYearId,
        public readonly int $periodNumber,
        public readonly string $periodName,
        public readonly string $startDate,
        public readonly string $endDate
    ) {}
}
