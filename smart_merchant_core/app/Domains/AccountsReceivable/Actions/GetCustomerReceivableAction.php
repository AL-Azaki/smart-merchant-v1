<?php

namespace App\Domains\AccountsReceivable\Actions;

use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;

class GetCustomerReceivableAction
{
    private CustomerReceivableRepositoryInterface $repository;

    public function __construct(CustomerReceivableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): ?CustomerReceivable
    {
        return $this->repository->findById($id);
    }
}
