<?php

namespace App\Domains\Finance\DTOs;

class FiscalYearSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $code = null,
        public readonly ?string $name = null,
        public readonly ?string $status = null,
        public readonly int $perPage = 15
    ) {}
}
