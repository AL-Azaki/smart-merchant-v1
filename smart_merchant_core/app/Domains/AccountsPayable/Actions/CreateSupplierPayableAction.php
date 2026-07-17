<?php

namespace App\Domains\AccountsPayable\Actions;

use App\Domains\AccountsPayable\Models\SupplierPayable;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use Exception;

class CreateSupplierPayableAction
{
    private SupplierPayableRepositoryInterface $repository;

    public function __construct(SupplierPayableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): SupplierPayable
    {
        try {
            return $this->repository->create($data);
        } catch (Exception $e) {
            throw $e;
        }
    }
}
