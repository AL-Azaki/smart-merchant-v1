<?php

namespace App\Domains\Finance\DTOs;

class CashRegisterListCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly int $perPage = 15
    ) {}
}
