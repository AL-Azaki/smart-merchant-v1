<?php

namespace App\Domains\Finance\DTOs;

class ViewFiscalYearDTO
{
    public function __construct(
        public readonly string $fiscalYearId,
        public readonly string $businessId
    ) {}
}
