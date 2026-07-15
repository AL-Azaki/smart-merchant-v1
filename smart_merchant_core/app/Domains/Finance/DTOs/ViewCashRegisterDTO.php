<?php

namespace App\Domains\Finance\DTOs;

class ViewCashRegisterDTO
{
    public function __construct(
        public readonly string $cashRegisterId,
        public readonly string $businessId
    ) {}
}
