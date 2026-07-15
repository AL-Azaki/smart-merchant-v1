<?php

namespace App\Domains\Core\Actions\Currency;

use App\Domains\Core\DTOs\CurrencyListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListCurrenciesAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(CurrencyListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
