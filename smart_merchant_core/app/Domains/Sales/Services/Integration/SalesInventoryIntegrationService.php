<?php

namespace App\Domains\Sales\Services\Integration;

use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Inventory\Services\InventoryStockService;
use Exception;
use Illuminate\Support\Facades\DB;

class SalesInventoryIntegrationService
{
    public function __construct(
        private InventoryTransactionBuilder $builder,
        private InventoryStockService $inventoryStockService
    ) {}

    public function dispatchStockForInvoice(SalesInvoice $invoice): void
    {
        $invoice->loadMissing('items');

        if ($invoice->items->isEmpty()) {
            return;
        }

        if ($invoice->status !== 'Posted') {
            throw new Exception("Cannot dispatch stock for an invoice that is not Posted.");
        }

        $alreadyDispatched = $this->inventoryStockService->hasTransactionForReference(
            $invoice->business_id,
            'SalesInvoice',
            $invoice->id
        );

        if ($alreadyDispatched) {
            throw new Exception("Inventory has already been dispatched for this invoice.");
        }

        $transactionData = $this->builder->build($invoice);

        DB::transaction(function () use ($transactionData) {
            $this->inventoryStockService->decreaseStockBulk(
                $transactionData['business_id'],
                $transactionData['warehouse_id'],
                $transactionData['lines'],
                $transactionData['reference_type'],
                $transactionData['reference_id'],
                $transactionData['notes']
            );
        });
    }
}
