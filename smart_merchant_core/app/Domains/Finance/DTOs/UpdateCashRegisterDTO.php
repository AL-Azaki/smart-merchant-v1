<?php

namespace App\Domains\Finance\DTOs;

class UpdateCashRegisterDTO
{
    public function __construct(
        public readonly string $cashRegisterId,
        public readonly string $businessId,
        public readonly string $branchId,
        public readonly string $registerName
    ) {}
}
