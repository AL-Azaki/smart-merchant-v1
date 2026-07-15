<?php

namespace App\Domains\Finance\DTOs;

class UpdateChartOfAccountDTO
{
    public function __construct(
        public readonly string $accountId,
        public readonly string $businessId,
        public readonly string $accountName,
        public readonly ?string $accountCode = null,
        public readonly ?string $parentAccountId = null,
        public readonly ?string $description = null,
        public readonly bool $isActive = true
    ) {}
}
