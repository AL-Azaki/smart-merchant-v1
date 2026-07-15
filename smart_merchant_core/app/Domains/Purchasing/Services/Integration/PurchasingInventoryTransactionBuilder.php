<?php

namespace App\Domains\Purchasing\Services\Integration;

use App\Domains\Purchasing\Models\PurchaseInvoice;

class PurchasingInventoryTransactionBuilder
{
    public function __construct(
        private PurchasingInventoryTransactionLinesBuilder $linesBuilder
    ) {}

    public function build(PurchaseInvoice $invoice): array
    {
        return [
            'business_id' => $invoice->business_id,
            'warehouse_id' => $invoice->warehouse_id,
            'transaction_type' => 'Receipt',
            'reference_type' => 'PurchaseInvoice',
            'reference_id' => $invoice->id,
            'notes' => 'Received from Purchase Invoice ' . $invoice->invoice_number,
            'lines' => $this->linesBuilder->build($invoice->items),
        ];
    }
}
