<?php

namespace App\Domains\Sales\Actions\SalesInvoice;

use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;
use Illuminate\Support\Collection;

class ListSalesInvoicesAction
{
    public function __construct(
        private SalesInvoiceRepositoryInterface $repository
    ) {}

    public function execute(string $businessId): Collection
    {
        return $this->repository->getAll($businessId);
    }
}
