<?php

namespace App\Domains\Finance\DTOs;

class CreateBankAccountDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $currencyId,
        public readonly string $accountNumber,
        public readonly string $bankName,
        public readonly ?string $branchId = null,
        public readonly ?string $iban = null,
        public readonly ?string $displayName = null,
        public readonly ?string $description = null,
        public readonly bool $isActive = true,
        public readonly bool $isDefault = false
    ) {}
}
