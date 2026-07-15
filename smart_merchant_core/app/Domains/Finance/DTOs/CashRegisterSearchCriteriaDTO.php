<?php

namespace App\Domains\Finance\DTOs;

class CashRegisterSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $registerName = null,
        public readonly ?string $branchId = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15
    ) {}
}
