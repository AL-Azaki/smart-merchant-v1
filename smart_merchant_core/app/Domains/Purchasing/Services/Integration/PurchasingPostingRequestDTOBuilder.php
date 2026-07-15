<?php

namespace App\Domains\Purchasing\Services\Integration;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingLineDTO;
use App\Domains\Finance\Actions\AccountMapping\ResolveAccountMappingAction;

class PurchasingPostingRequestDTOBuilder
{
    public function __construct(
        private ResolveAccountMappingAction $resolveAccountMapping
    ) {}

    public function build(PurchaseInvoice $invoice): PostingRequestDTO
    {
        $lines = [];

        // 1. Inventory Asset (Debit)
        if ($invoice->base_sub_total > 0) {
            $inventoryAccountId = $this->resolveAccountMapping->execute($invoice->business_id, 'inventory_asset');
            $lines[] = new PostingLineDTO(
                accountId: $inventoryAccountId,
                debitAmount: (float) $invoice->base_sub_total,
                creditAmount: 0.00,
                description: 'Inventory receipt for Purchase Invoice ' . $invoice->invoice_number,
                branchId: $invoice->branch_id
            );
        }

        // 2. Tax (Debit)
        if ($invoice->base_tax_total > 0) {
            $taxAccountId = $this->resolveAccountMapping->execute($invoice->business_id, 'input_vat');
            $lines[] = new PostingLineDTO(
                accountId: $taxAccountId,
                debitAmount: (float) $invoice->base_tax_total,
                creditAmount: 0.00,
                description: 'Tax for Purchase Invoice ' . $invoice->invoice_number,
                branchId: $invoice->branch_id
            );
        }

        // 3. Discount (Credit)
        if ($invoice->base_discount_total > 0) {
            $discountAccountId = $this->resolveAccountMapping->execute($invoice->business_id, 'discount_received');
            $lines[] = new PostingLineDTO(
                accountId: $discountAccountId,
                debitAmount: 0.00,
                creditAmount: (float) $invoice->base_discount_total,
                description: 'Discount for Purchase Invoice ' . $invoice->invoice_number,
                branchId: $invoice->branch_id
            );
        }

        // 4. Accounts Payable (Credit)
        if ($invoice->base_grand_total > 0) {
            $payableAccountId = $this->resolveAccountMapping->execute($invoice->business_id, 'accounts_payable');
            $lines[] = new PostingLineDTO(
                accountId: $payableAccountId,
                debitAmount: 0.00,
                creditAmount: (float) $invoice->base_grand_total,
                description: 'Accounts Payable for Purchase Invoice ' . $invoice->invoice_number,
                branchId: $invoice->branch_id
            );
        }

        return new PostingRequestDTO(
            businessId: $invoice->business_id,
            referenceType: 'PurchaseInvoice',
            referenceId: $invoice->id,
            description: 'Posting for Purchase Invoice ' . $invoice->invoice_number,
            journalDate: $invoice->purchase_date->format('Y-m-d'),
            lines: $lines
        );
    }
}
