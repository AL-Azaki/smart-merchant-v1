<?php

namespace App\Domains\Finance\DTOs;

class CreateFiscalYearDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $fiscalYearCode,
        public readonly string $fiscalYearName,
        public readonly string $startDate,
        public readonly string $endDate,
        public readonly ?string $description = null
    ) {}
}
