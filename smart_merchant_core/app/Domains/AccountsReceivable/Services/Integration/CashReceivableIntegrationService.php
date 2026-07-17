<?php

namespace App\Domains\AccountsReceivable\Services\Integration;

use App\Domains\Finance\Models\CashTransaction;

class CashReceivableIntegrationService
{
    public function handleCashSettlement(CashTransaction $transaction, string $customerId, float $allocatedAmount): void
    {
        // Cash Management owns cash. AR reacts after successful cash processing.
        // Entry logic mirrors Banking integration, routing through the App Layer to update balances.
    }
}
