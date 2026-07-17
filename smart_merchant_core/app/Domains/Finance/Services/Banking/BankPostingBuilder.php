<?php

namespace App\Domains\Finance\Services\Banking;

use App\Domains\Finance\Models\BankTransaction;
use App\Domains\Finance\DTOs\PostingRequestDTO;
use App\Domains\Finance\DTOs\JournalEntryLineDTO;
use App\Domains\Finance\Contracts\AccountMappingInterface;

class BankPostingBuilder
{
    private AccountMappingInterface $accountMapping;

    public function __construct(AccountMappingInterface $accountMapping)
    {
        $this->accountMapping = $accountMapping;
    }

    public function build(BankTransaction $transaction): PostingRequestDTO
    {
        $businessId = $transaction->business_id;
        $amount = $transaction->amount;
        $currencyId = $transaction->bankAccount->currency_id;

        $bankAssetAccountId = $this->accountMapping->getAccountId($businessId, 'BankAssetAccount');
        $counterAccountId = $this->resolveCounterAccount($transaction);

        $lines = [];

        if ($transaction->direction === 'Credit') {
            // Credit to bank = inflow → Debit Bank Asset, Credit Counter
            $lines[] = new JournalEntryLineDTO($bankAssetAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($counterAccountId, 0, $amount);
        } else {
            // Debit from bank = outflow → Credit Bank Asset, Debit Counter
            $lines[] = new JournalEntryLineDTO($counterAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($bankAssetAccountId, 0, $amount);
        }

        return new PostingRequestDTO(
            businessId: $businessId,
            documentType: 'BankTransaction',
            documentId: $transaction->id,
            currencyId: $currencyId,
            description: $transaction->notes ?? "Bank {$transaction->transaction_type}",
            date: $transaction->created_at->format('Y-m-d'),
            lines: $lines
        );
    }

    private function resolveCounterAccount(BankTransaction $transaction): string
    {
        $typeMapping = [
            'Deposit' => 'CashInTransitAccount',
            'Withdrawal' => 'CashInTransitAccount',
            'Transfer In' => 'BankTransferClearingAccount',
            'Transfer Out' => 'BankTransferClearingAccount',
            'Adjustment' => 'BankDiscrepancyAccount',
            'Bank Fee' => 'BankChargesExpenseAccount',
            'Interest' => 'InterestIncomeAccount',
            'Opening Balance' => 'OwnerEquityAccount',
        ];

        $accountCode = $typeMapping[$transaction->transaction_type] ?? 'MiscellaneousExpenseAccount';

        return $this->accountMapping->getAccountId($transaction->business_id, $accountCode);
    }
}
