<?php

namespace App\Domains\AccountsPayable\Actions;

use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use Illuminate\Support\Collection;

class ListSupplierPayablesAction
{
    private SupplierPayableRepositoryInterface $repository;

    public function __construct(SupplierPayableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $filters = []): Collection
    {
        return $this->repository->list($filters);
    }
}
