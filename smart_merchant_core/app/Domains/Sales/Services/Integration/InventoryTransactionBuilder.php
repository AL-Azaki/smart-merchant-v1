<?php

namespace App\Domains\Sales\Services\Integration;

use App\Domains\Sales\Models\SalesInvoice;

class InventoryTransactionBuilder
{
    public function __construct(
        private InventoryTransactionLinesBuilder $linesBuilder
    ) {}

    public function build(SalesInvoice $invoice): array
    {
        $warehouseId = $invoice->items->first()?->warehouse_id;

        if (!$warehouseId) {
            throw new \Exception("Cannot build inventory transaction: No warehouse found on invoice items.");
        }

        return [
            'business_id' => $invoice->business_id,
            'warehouse_id' => $warehouseId,
            'reference_type' => 'SalesInvoice',
            'reference_id' => $invoice->id,
            'notes' => 'Generated automatically from Sales Invoice: ' . $invoice->invoice_number,
            'lines' => $this->linesBuilder->build($invoice->items),
        ];
    }
}
