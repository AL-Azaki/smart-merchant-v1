<?php

namespace App\Domains\Sales\Actions\SalesInvoice;

use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;

class UpdateSalesInvoiceAction
{
    public function __construct(
        private SalesInvoiceRepositoryInterface $repository
    ) {}

    public function execute(SalesInvoice $invoice, array $data): SalesInvoice
    {
        if ($invoice->status !== 'Draft') {
            throw new \Exception('Cannot update a non-draft invoice.');
        }

        return $this->repository->update($invoice, $data);
    }
}
