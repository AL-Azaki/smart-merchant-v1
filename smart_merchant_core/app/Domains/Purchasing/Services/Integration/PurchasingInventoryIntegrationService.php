<?php

namespace App\Domains\Purchasing\Services\Integration;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Inventory\Services\InventoryStockService;
use Exception;
use Illuminate\Support\Facades\DB;

class PurchasingInventoryIntegrationService
{
    public function __construct(
        private PurchasingInventoryTransactionBuilder $builder,
        private InventoryStockService $inventoryStockService
    ) {}

    public function receiveStockForInvoice(PurchaseInvoice $invoice): void
    {
        $invoice->loadMissing('items');

        if ($invoice->items->isEmpty()) {
            return;
        }

        if ($invoice->status !== 'Posted') {
            throw new Exception("Cannot receive stock for an invoice that is not Posted.");
        }

        $alreadyReceived = $this->inventoryStockService->hasTransactionForReference(
            $invoice->business_id,
            'PurchaseInvoice',
            $invoice->id
        );

        if ($alreadyReceived) {
            throw new Exception("Inventory has already been received for this invoice.");
        }

        $transactionData = $this->builder->build($invoice);

        DB::transaction(function () use ($transactionData) {
            foreach ($transactionData['lines'] as $line) {
                $this->inventoryStockService->increaseStock(
                    $transactionData['business_id'],
                    $transactionData['warehouse_id'],
                    $line['product_unit_id'],
                    $line['quantity'],
                    $line['unit_cost'],
                    $transactionData['reference_type'],
                    $transactionData['reference_id'],
                    $transactionData['notes']
                );
            }
        });
    }
}
