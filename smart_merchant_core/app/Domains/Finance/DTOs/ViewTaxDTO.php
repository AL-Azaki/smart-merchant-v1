<?php

namespace App\Domains\Finance\DTOs;

class ViewTaxDTO
{
    public function __construct(
        public readonly string $taxId,
        public readonly string $businessId
    ) {}
}
