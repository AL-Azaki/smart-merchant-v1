<?php

namespace App\Domains\Finance\Services\CashManagement;

use App\Domains\Finance\Models\CashTransaction;
use App\Domains\Finance\DTOs\PostingRequestDTO;
use App\Domains\Finance\DTOs\JournalEntryLineDTO;
use App\Domains\Finance\Contracts\AccountMappingInterface;

class CashPostingBuilder
{
    private AccountMappingInterface $accountMapping;

    public function __construct(AccountMappingInterface $accountMapping)
    {
        $this->accountMapping = $accountMapping;
    }

    public function build(CashTransaction $transaction): PostingRequestDTO
    {
        $businessId = $transaction->business_id;
        $amount = $transaction->amount;
        
        // This resolves the base currency of the register natively
        $currencyId = $transaction->cashRegister->currency_id;
        
        // Dynamic Resolution without hardcoded IDs
        $cashAccountId = $this->accountMapping->getAccountId($businessId, 'CashAccount');
        $counterAccountId = $this->resolveCounterAccount($transaction);
        
        $lines = [];
        
        if (in_array($transaction->transaction_type, ['Deposit', 'Transfer In', 'Receipt', 'Adjustment'])) {
            // Debit Cash, Credit Counter
            $lines[] = new JournalEntryLineDTO($cashAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($counterAccountId, 0, $amount);
        } else {
            // Credit Cash, Debit Counter
            $lines[] = new JournalEntryLineDTO($counterAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($cashAccountId, 0, $amount);
        }
        
        return new PostingRequestDTO(
            businessId: $businessId,
            documentType: 'CashTransaction',
            documentId: $transaction->id,
            currencyId: $currencyId,
            description: $transaction->notes ?? "Cash {$transaction->transaction_type}",
            date: $transaction->created_at->format('Y-m-d'),
            lines: $lines
        );
    }
    
    private function resolveCounterAccount(CashTransaction $transaction): string
    {
        // Example dynamic resolution mapping based on transaction type
        $typeMapping = [
            'Deposit' => 'OwnerEquityAccount',
            'Withdrawal' => 'DrawingsAccount',
            'Transfer In' => 'CashTransferClearingAccount',
            'Transfer Out' => 'CashTransferClearingAccount',
            'Adjustment' => 'CashDiscrepancyAccount',
            'Payment' => 'AccountsPayable',
            'Receipt' => 'AccountsReceivable'
        ];
        
        $accountCode = $typeMapping[$transaction->transaction_type] ?? 'MiscellaneousExpenseAccount';
        
        return $this->accountMapping->getAccountId($transaction->business_id, $accountCode);
    }
}
