<?php

namespace App\Domains\Finance\DTOs;

class TaxListCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly int $perPage = 15
    ) {}
}
