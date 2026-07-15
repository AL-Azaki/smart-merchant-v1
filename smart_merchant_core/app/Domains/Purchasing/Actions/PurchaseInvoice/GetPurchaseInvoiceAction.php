<?php

namespace App\Domains\Purchasing\Actions\PurchaseInvoice;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Repositories\Contracts\PurchaseInvoiceRepositoryInterface;

class GetPurchaseInvoiceAction
{
    public function __construct(
        private PurchaseInvoiceRepositoryInterface $repository
    ) {}

    public function execute(string $businessId, string $id): ?PurchaseInvoice
    {
        return $this->repository->findById($businessId, $id);
    }
}
