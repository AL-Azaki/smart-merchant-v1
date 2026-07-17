<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;

class LoadBankAccountAggregateAction
{
    private BankAccountRepositoryInterface $repository;

    public function __construct(BankAccountRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): ?BankAccount
    {
        return $this->repository->loadAggregate($id);
    }
}
