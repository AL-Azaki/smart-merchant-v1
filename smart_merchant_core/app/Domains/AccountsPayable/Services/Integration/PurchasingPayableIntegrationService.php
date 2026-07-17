<?php

namespace App\Domains\AccountsPayable\Services\Integration;

use App\Domains\AccountsPayable\Actions\CreateSupplierPayableAction;
use App\Domains\AccountsPayable\Actions\RecordPayableEntryAction;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use App\Domains\Purchasing\Models\PurchaseInvoice;

class PurchasingPayableIntegrationService
{
    private SupplierPayableRepositoryInterface $repository;
    private CreateSupplierPayableAction $createAction;
    private RecordPayableEntryAction $recordEntryAction;

    public function __construct(
        SupplierPayableRepositoryInterface $repository,
        CreateSupplierPayableAction $createAction,
        RecordPayableEntryAction $recordEntryAction
    ) {
        $this->repository = $repository;
        $this->createAction = $createAction;
        $this->recordEntryAction = $recordEntryAction;
    }

    public function handlePurchaseInvoiceFinalized(PurchaseInvoice $invoice): void
    {
        $payable = $this->repository->findBySupplier($invoice->business_id, $invoice->supplier_id);

        if (! $payable) {
            $payable = $this->createAction->execute([
                'business_id' => $invoice->business_id,
                'supplier_id' => $invoice->supplier_id,
                'currency_id' => $invoice->currency_id,
                'due_date' => $invoice->due_date,
            ]);
        }

        $entryData = [
            'business_id' => $invoice->business_id,
            'entry_type' => 'Invoice',
            'direction' => 'Credit',
            'amount' => $invoice->total_amount,
            'document_type' => get_class($invoice),
            'document_id' => $invoice->id,
            'created_by' => $invoice->created_by,
        ];

        $this->recordEntryAction->execute($payable->id, $entryData);
    }
}
