<?php

namespace App\Domains\Finance\Contracts\Integration;

use App\Domains\Finance\DTOs\Integration\InvoiceSettlementRequestDTO;

interface PurchasingSettlementInterface
{
    public function settle(InvoiceSettlementRequestDTO $request): void;
    
    public function reverse(InvoiceSettlementRequestDTO $request): void;
}
