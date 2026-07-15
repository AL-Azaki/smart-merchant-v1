<?php

namespace App\Domains\Finance\DTOs;

class CreateChartOfAccountDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly int $accountTypeId,
        public readonly string $accountName,
        public readonly string $normalBalance,
        public readonly ?string $accountCode = null,
        public readonly ?string $parentAccountId = null,
        public readonly ?string $currencyId = null,
        public readonly ?string $description = null,
        public readonly ?string $accountCategory = null,
        public readonly bool $allowPosting = false,
        public readonly bool $isSystem = false,
        public readonly bool $isActive = true,
        public readonly int $accountLevel = 1
    ) {}
}
