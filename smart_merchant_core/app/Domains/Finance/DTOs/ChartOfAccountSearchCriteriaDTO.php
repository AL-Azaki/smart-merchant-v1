<?php

namespace App\Domains\Finance\DTOs;

class ChartOfAccountSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $name = null,
        public readonly ?string $code = null,
        public readonly ?bool $status = null,
        public readonly ?int $accountTypeId = null,
        public readonly int $perPage = 15
    ) {}
}
