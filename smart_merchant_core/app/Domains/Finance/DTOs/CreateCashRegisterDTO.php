<?php

namespace App\Domains\Finance\DTOs;

class CreateCashRegisterDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $branchId,
        public readonly string $registerName,
        public readonly bool $isActive = true
    ) {}
}
