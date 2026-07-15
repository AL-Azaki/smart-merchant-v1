<?php

namespace App\Domains\Finance\DTOs;

class BankAccountSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $bankName = null,
        public readonly ?string $accountNumber = null,
        public readonly ?string $currencyId = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15
    ) {}
}
