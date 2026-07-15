<?php

namespace App\Domains\Finance\DTOs;

class ViewChartOfAccountDTO
{
    public function __construct(
        public readonly string $accountId,
        public readonly string $businessId
    ) {}
}
