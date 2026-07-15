<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\DTOs\TaxSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchTaxesAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(TaxSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
