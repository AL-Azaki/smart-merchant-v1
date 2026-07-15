<?php

namespace App\Domains\Finance\DTOs;

class PaymentTermSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $termName = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15
    ) {}
}
