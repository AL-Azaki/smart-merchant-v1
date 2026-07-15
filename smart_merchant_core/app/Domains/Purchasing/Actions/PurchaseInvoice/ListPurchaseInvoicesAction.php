<?php

namespace App\Domains\Purchasing\Actions\PurchaseInvoice;

use App\Domains\Purchasing\Repositories\Contracts\PurchaseInvoiceRepositoryInterface;
use Illuminate\Support\Collection;

class ListPurchaseInvoicesAction
{
    public function __construct(
        private PurchaseInvoiceRepositoryInterface $repository
    ) {}

    public function execute(string $businessId): Collection
    {
        return $this->repository->getAll($businessId);
    }
}
