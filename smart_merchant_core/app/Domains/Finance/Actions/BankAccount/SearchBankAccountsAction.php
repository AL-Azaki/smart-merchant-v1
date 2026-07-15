<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\DTOs\BankAccountSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchBankAccountsAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(BankAccountSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
