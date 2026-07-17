<?php

namespace App\Domains\AccountsPayable\Services\Integration;

use App\Domains\Finance\Models\BankTransaction;

class BankingPayableIntegrationService
{
    /**
     * AP reacts to Banking only after Banking successfully processes the disbursement.
     * Banking owns bank transactions — AP only updates payable state post-settlement.
     */
    public function handleBankSettlement(BankTransaction $transaction, string $supplierId, float $allocatedAmount): void
    {
        // Banking owns the bank transaction lifecycle.
        // AP reacts via the Payments domain or directly through the Application Layer
        // to record the payable entry after successful bank processing.
    }
}
