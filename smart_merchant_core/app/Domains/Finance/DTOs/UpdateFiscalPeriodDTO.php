<?php

namespace App\Domains\Finance\DTOs;

class UpdateFiscalPeriodDTO
{
    public function __construct(
        public readonly string $fiscalPeriodId,
        public readonly string $businessId,
        public readonly string $periodName,
        public readonly string $startDate,
        public readonly string $endDate
    ) {}
}
