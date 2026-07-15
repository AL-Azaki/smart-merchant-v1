<?php

namespace App\Domains\Sales\Actions\SalesInvoice;

use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;

class CreateSalesInvoiceAction
{
    public function __construct(
        private SalesInvoiceRepositoryInterface $repository
    ) {}

    public function execute(array $data): SalesInvoice
    {
        return $this->repository->create($data);
    }
}
