<?php

namespace App\Domains\Finance\Actions\ExchangeRate;

use App\Domains\Finance\DTOs\ExchangeRateSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchExchangeRatesAction
{
    public function __construct(private readonly ExchangeRateRepositoryInterface $repository) {}

    public function handle(ExchangeRateSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
