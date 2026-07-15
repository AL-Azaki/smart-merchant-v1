<?php

namespace App\Domains\Finance\DTOs;

class ViewFiscalPeriodDTO
{
    public function __construct(
        public readonly string $fiscalPeriodId,
        public readonly string $businessId
    ) {}
}
