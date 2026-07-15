<?php

namespace App\Domains\Core\Actions\Account;

use App\Domains\Core\DTOs\AccountListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListAccountsAction
{
    public function __construct(private readonly AccountRepositoryInterface $repository) {}

    public function handle(AccountListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
