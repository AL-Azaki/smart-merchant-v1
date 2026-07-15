<?php

namespace App\Domains\Finance\DTOs;

class ViewExchangeRateDTO
{
    public function __construct(
        public readonly string $exchangeRateId,
        public readonly string $businessId
    ) {}
}
