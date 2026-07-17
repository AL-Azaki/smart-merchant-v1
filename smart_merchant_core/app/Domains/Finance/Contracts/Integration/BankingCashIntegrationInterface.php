<?php

namespace App\Domains\Finance\Contracts\Integration;

use App\Domains\Finance\Models\CashTransaction;

interface BankingCashIntegrationInterface
{
    /**
     * Handles the bank-side of a cash-to-bank deposit operation.
     * Called within an existing transaction boundary.
     */
    public function handleCashDeposit(CashTransaction $cashTransaction, string $bankAccountId): void;

    /**
     * Handles the bank-side of a bank-to-cash withdrawal operation.
     * Called within an existing transaction boundary.
     */
    public function handleBankWithdrawal(string $bankAccountId, string $businessId, float $amount, ?string $createdBy): void;
}
