<?php

namespace App\Domains\Core\Actions\Currency;

use App\Domains\Core\DTOs\CurrencySearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchCurrenciesAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(CurrencySearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
