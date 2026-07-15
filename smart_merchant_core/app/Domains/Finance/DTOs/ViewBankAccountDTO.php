<?php

namespace App\Domains\Finance\DTOs;

class ViewBankAccountDTO
{
    public function __construct(
        public readonly string $bankAccountId,
        public readonly string $businessId
    ) {}
}
