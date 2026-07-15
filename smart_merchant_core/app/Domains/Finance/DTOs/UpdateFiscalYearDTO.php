<?php

namespace App\Domains\Finance\DTOs;

class UpdateFiscalYearDTO
{
    public function __construct(
        public readonly string $fiscalYearId,
        public readonly string $businessId,
        public readonly string $fiscalYearName,
        public readonly string $startDate,
        public readonly string $endDate,
        public readonly ?string $description = null
    ) {}
}
