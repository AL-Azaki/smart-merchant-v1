<?php

namespace App\Domains\AccountsReceivable\Actions;

use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use Illuminate\Support\Collection;

class ListCustomerReceivablesAction
{
    private CustomerReceivableRepositoryInterface $repository;

    public function __construct(CustomerReceivableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $filters = []): Collection
    {
        return $this->repository->list($filters);
    }
}
