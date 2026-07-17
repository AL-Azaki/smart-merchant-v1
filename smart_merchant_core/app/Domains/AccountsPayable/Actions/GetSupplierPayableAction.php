<?php

namespace App\Domains\AccountsPayable\Actions;

use App\Domains\AccountsPayable\Models\SupplierPayable;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;

class GetSupplierPayableAction
{
    private SupplierPayableRepositoryInterface $repository;

    public function __construct(SupplierPayableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): ?SupplierPayable
    {
        return $this->repository->findById($id);
    }
}
