<?php

namespace App\Domains\AccountsPayable\Services\Integration;

use App\Domains\Finance\Models\CashTransaction;

class CashPayableIntegrationService
{
    /**
     * AP reacts to Cash Management only after successful cash processing.
     * Cash Management owns cash transactions — AP only updates payable state post-settlement.
     */
    public function handleCashSettlement(CashTransaction $transaction, string $supplierId, float $allocatedAmount): void
    {
        // Cash Management owns the cash transaction lifecycle.
        // AP reacts via the Payments domain or directly through the Application Layer
        // to record the payable entry after successful cash processing.
    }
}
