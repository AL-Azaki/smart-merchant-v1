<?php

namespace App\Domains\AccountsReceivable\Actions;

use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use Exception;

class CreateCustomerReceivableAction
{
    private CustomerReceivableRepositoryInterface $repository;

    public function __construct(CustomerReceivableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): CustomerReceivable
    {
        try {
            return $this->repository->create($data);
        } catch (Exception $e) {
            throw $e;
        }
    }
}
