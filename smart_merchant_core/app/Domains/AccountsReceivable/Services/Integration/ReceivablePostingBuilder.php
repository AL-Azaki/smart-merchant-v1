<?php

namespace App\Domains\AccountsReceivable\Services\Integration;

use App\Domains\AccountsReceivable\Models\ReceivableEntry;
use App\Domains\Finance\DTOs\PostingRequestDTO;
use App\Domains\Finance\DTOs\JournalEntryLineDTO;
use App\Domains\Finance\Contracts\AccountMappingInterface;

class ReceivablePostingBuilder
{
    private AccountMappingInterface $accountMapping;

    public function __construct(AccountMappingInterface $accountMapping)
    {
        $this->accountMapping = $accountMapping;
    }

    public function build(ReceivableEntry $entry): PostingRequestDTO
    {
        $businessId = $entry->business_id;
        $amount = $entry->amount;
        $currencyId = $entry->customerReceivable->currency_id;

        $arAccountId = $this->accountMapping->getAccountId($businessId, 'AccountsReceivable');
        $counterAccountId = $this->resolveCounterAccount($entry);

        $lines = [];

        if ($entry->direction === 'Debit') {
            // e.g., Invoice -> Debit AR, Credit Revenue/Counter
            $lines[] = new JournalEntryLineDTO($arAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($counterAccountId, 0, $amount);
        } else {
            // e.g., Payment or Write-off -> Credit AR, Debit Counter
            $lines[] = new JournalEntryLineDTO($counterAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($arAccountId, 0, $amount);
        }

        return new PostingRequestDTO(
            businessId: $businessId,
            documentType: 'ReceivableEntry',
            documentId: $entry->id,
            currencyId: $currencyId,
            description: "AR {$entry->entry_type} Entry",
            date: $entry->created_at->format('Y-m-d'),
            lines: $lines
        );
    }

    private function resolveCounterAccount(ReceivableEntry $entry): string
    {
        return match ($entry->entry_type) {
            'Invoice' => $this->accountMapping->getAccountId($entry->business_id, 'SalesRevenueAccount'),
            'Payment' => $this->accountMapping->getAccountId($entry->business_id, 'PaymentClearingAccount'),
            'Write-off' => $this->accountMapping->getAccountId($entry->business_id, 'BadDebtExpenseAccount'),
            'Adjustment' => $this->accountMapping->getAccountId($entry->business_id, 'ReceivableAdjustmentAccount'),
            default => $this->accountMapping->getAccountId($entry->business_id, 'MiscellaneousAccount'),
        };
    }
}
