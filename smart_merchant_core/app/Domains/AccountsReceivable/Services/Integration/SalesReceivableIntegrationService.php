<?php

namespace App\Domains\AccountsReceivable\Services\Integration;

use App\Domains\AccountsReceivable\Actions\CreateCustomerReceivableAction;
use App\Domains\AccountsReceivable\Actions\RecordReceivableEntryAction;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use App\Domains\Sales\Models\SalesInvoice;

class SalesReceivableIntegrationService
{
    private CustomerReceivableRepositoryInterface $repository;
    private CreateCustomerReceivableAction $createAction;
    private RecordReceivableEntryAction $recordEntryAction;

    public function __construct(
        CustomerReceivableRepositoryInterface $repository,
        CreateCustomerReceivableAction $createAction,
        RecordReceivableEntryAction $recordEntryAction
    ) {
        $this->repository = $repository;
        $this->createAction = $createAction;
        $this->recordEntryAction = $recordEntryAction;
    }

    public function handleSalesInvoiceFinalized(SalesInvoice $invoice): void
    {
        $receivable = $this->repository->findByCustomer($invoice->business_id, $invoice->customer_id);

        if (! $receivable) {
            $receivable = $this->createAction->execute([
                'business_id' => $invoice->business_id,
                'customer_id' => $invoice->customer_id,
                'currency_id' => $invoice->currency_id,
                'credit_limit' => 0.00, // Default or fetched from customer profile
                'due_date' => $invoice->due_date,
            ]);
        }

        $entryData = [
            'business_id' => $invoice->business_id,
            'entry_type' => 'Invoice',
            'direction' => 'Debit',
            'amount' => $invoice->total_amount,
            'document_type' => get_class($invoice),
            'document_id' => $invoice->id,
            'created_by' => $invoice->created_by,
        ];

        $this->recordEntryAction->execute($receivable->id, $entryData);
    }
}
