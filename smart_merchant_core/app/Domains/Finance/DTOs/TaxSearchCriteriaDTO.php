<?php

namespace App\Domains\Finance\DTOs;

class TaxSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $taxName = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15
    ) {}
}
