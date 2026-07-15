<?php

namespace App\Domains\Purchasing\Actions\PurchaseInvoice;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Repositories\Contracts\PurchaseInvoiceRepositoryInterface;
use Exception;

class UpdatePurchaseInvoiceAction
{
    public function __construct(
        private PurchaseInvoiceRepositoryInterface $repository
    ) {}

    public function execute(PurchaseInvoice $invoice, array $data): PurchaseInvoice
    {
        if ($invoice->status !== 'Draft') {
            throw new Exception("Cannot update a purchase invoice that is not in Draft status.");
        }

        return $this->repository->update($invoice, $data);
    }
}
