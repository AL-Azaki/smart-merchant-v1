<?php

namespace App\Domains\Core\Actions\Account;

use App\Domains\Core\DTOs\AccountSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchAccountsAction
{
    public function __construct(private readonly AccountRepositoryInterface $repository) {}

    public function handle(AccountSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
