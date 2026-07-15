<?php

namespace App\Domains\Purchasing\Actions\PurchaseInvoice;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Repositories\Contracts\PurchaseInvoiceRepositoryInterface;

class CreatePurchaseInvoiceAction
{
    public function __construct(
        private PurchaseInvoiceRepositoryInterface $repository
    ) {}

    public function execute(array $data): PurchaseInvoice
    {
        $data['status'] = 'Draft';
        return $this->repository->create($data);
    }
}
