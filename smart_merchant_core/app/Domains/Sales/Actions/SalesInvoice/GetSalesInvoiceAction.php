<?php

namespace App\Domains\Sales\Actions\SalesInvoice;

use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;

class GetSalesInvoiceAction
{
    public function __construct(
        private SalesInvoiceRepositoryInterface $repository
    ) {}

    public function execute(string $businessId, string $id): ?SalesInvoice
    {
        return $this->repository->findById($businessId, $id);
    }
}
