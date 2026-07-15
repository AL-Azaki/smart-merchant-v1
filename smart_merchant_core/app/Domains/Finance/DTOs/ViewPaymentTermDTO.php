<?php

namespace App\Domains\Finance\DTOs;

class ViewPaymentTermDTO
{
    public function __construct(
        public readonly string $paymentTermId,
        public readonly string $businessId
    ) {}
}
