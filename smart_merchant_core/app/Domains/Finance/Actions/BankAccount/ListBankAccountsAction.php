<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\DTOs\BankAccountListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListBankAccountsAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(BankAccountListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
