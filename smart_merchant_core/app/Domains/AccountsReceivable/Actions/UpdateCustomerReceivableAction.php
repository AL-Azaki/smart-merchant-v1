<?php

namespace App\Domains\AccountsReceivable\Actions;

use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use Exception;

class UpdateCustomerReceivableAction
{
    private CustomerReceivableRepositoryInterface $repository;

    public function __construct(CustomerReceivableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): CustomerReceivable
    {
        try {
            return $this->repository->update($id, $data);
        } catch (Exception $e) {
            throw $e;
        }
    }
}
