<?php

namespace App\Domains\AccountsPayable\Actions;

use App\Domains\AccountsPayable\Models\SupplierPayable;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use Exception;

class UpdateSupplierPayableAction
{
    private SupplierPayableRepositoryInterface $repository;

    public function __construct(SupplierPayableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): SupplierPayable
    {
        try {
            return $this->repository->update($id, $data);
        } catch (Exception $e) {
            throw $e;
        }
    }
}
