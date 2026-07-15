<?php

namespace App\Domains\Finance\Actions\ExchangeRate;

use App\Domains\Finance\DTOs\ExchangeRateListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListExchangeRatesAction
{
    public function __construct(private readonly ExchangeRateRepositoryInterface $repository) {}

    public function handle(ExchangeRateListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
