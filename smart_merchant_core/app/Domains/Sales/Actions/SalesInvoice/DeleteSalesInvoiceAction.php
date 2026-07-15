<?php

namespace App\Domains\Sales\Actions\SalesInvoice;

use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;

class DeleteSalesInvoiceAction
{
    public function __construct(
        private SalesInvoiceRepositoryInterface $repository
    ) {}

    public function execute(SalesInvoice $invoice): bool
    {
        if ($invoice->status !== 'Draft') {
            throw new \Exception('Cannot delete a non-draft invoice.');
        }

        return $this->repository->deleteDraft($invoice);
    }
}
