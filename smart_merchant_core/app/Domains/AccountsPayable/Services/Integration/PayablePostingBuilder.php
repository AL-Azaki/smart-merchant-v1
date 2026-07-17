<?php

namespace App\Domains\AccountsPayable\Services\Integration;

use App\Domains\AccountsPayable\Models\PayableEntry;
use App\Domains\Finance\DTOs\PostingRequestDTO;
use App\Domains\Finance\DTOs\JournalEntryLineDTO;
use App\Domains\Finance\Contracts\AccountMappingInterface;

class PayablePostingBuilder
{
    private AccountMappingInterface $accountMapping;

    public function __construct(AccountMappingInterface $accountMapping)
    {
        $this->accountMapping = $accountMapping;
    }

    public function build(PayableEntry $entry): PostingRequestDTO
    {
        $businessId = $entry->business_id;
        $amount = $entry->amount;
        $currencyId = $entry->supplierPayable->currency_id;

        $apAccountId = $this->accountMapping->getAccountId($businessId, 'AccountsPayable');
        $counterAccountId = $this->resolveCounterAccount($entry);

        $lines = [];

        if ($entry->direction === 'Credit') {
            // e.g., Invoice → Credit AP Liability, Debit Expense/Counter
            $lines[] = new JournalEntryLineDTO($counterAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($apAccountId, 0, $amount);
        } else {
            // e.g., Payment or Write-off → Debit AP Liability, Credit Counter
            $lines[] = new JournalEntryLineDTO($apAccountId, $amount, 0);
            $lines[] = new JournalEntryLineDTO($counterAccountId, 0, $amount);
        }

        return new PostingRequestDTO(
            businessId: $businessId,
            documentType: 'PayableEntry',
            documentId: $entry->id,
            currencyId: $currencyId,
            description: "AP {$entry->entry_type} Entry",
            date: $entry->created_at->format('Y-m-d'),
            lines: $lines
        );
    }

    private function resolveCounterAccount(PayableEntry $entry): string
    {
        return match ($entry->entry_type) {
            'Invoice' => $this->accountMapping->getAccountId($entry->business_id, 'PurchaseExpenseAccount'),
            'Payment' => $this->accountMapping->getAccountId($entry->business_id, 'PaymentClearingAccount'),
            'Write-off' => $this->accountMapping->getAccountId($entry->business_id, 'PayableWriteOffIncomeAccount'),
            'Adjustment' => $this->accountMapping->getAccountId($entry->business_id, 'PayableAdjustmentAccount'),
            default => $this->accountMapping->getAccountId($entry->business_id, 'MiscellaneousAccount'),
        };
    }
}
