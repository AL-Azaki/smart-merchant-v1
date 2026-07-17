<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Support\Collection;

class ListBankAccountsAction
{
    private BankAccountRepositoryInterface $repository;

    public function __construct(BankAccountRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $filters = []): Collection
    {
        return $this->repository->list($filters);
    }
}
