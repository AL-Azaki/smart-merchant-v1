<?php

namespace App\Domains\Finance\Services\Banking;

use App\Domains\Finance\Models\CashTransaction;

class CashToBankTransactionBuilder
{
    /**
     * Converts a Cash Management outflow (bank deposit) into a BankTransaction data array.
     * Contains NO business logic — pure data transformation only.
     */
    public function buildDeposit(CashTransaction $cashTransaction, string $bankAccountId): array
    {
        return [
            'business_id' => $cashTransaction->business_id,
            'transaction_type' => 'Deposit',
            'direction' => 'Credit',
            'amount' => $cashTransaction->amount,
            'document_type' => CashTransaction::class,
            'document_id' => $cashTransaction->id,
            'notes' => "Bank deposit from Cash Transaction #{$cashTransaction->id}",
            'created_by' => $cashTransaction->created_by,
        ];
    }

    /**
     * Converts a Bank withdrawal into a Cash Management inflow data array.
     * Contains NO business logic — pure data transformation only.
     */
    public function buildWithdrawal(string $bankAccountId, string $businessId, float $amount, ?string $createdBy): array
    {
        return [
            'business_id' => $businessId,
            'transaction_type' => 'Withdrawal',
            'direction' => 'Debit',
            'amount' => $amount,
            'notes' => "Bank withdrawal to Cash Register",
            'created_by' => $createdBy,
        ];
    }
}
