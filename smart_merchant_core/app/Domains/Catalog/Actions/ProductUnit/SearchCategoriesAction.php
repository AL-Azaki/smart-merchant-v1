<?php

namespace App\Domains\Catalog\Actions\productUnitUnit;

use App\Domains\Catalog\DTOs\productUnitUnitsearchCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\productUnitUnitRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchproductUnitUnitsAction
{
    public function __construct(private readonly productUnitUnitRepositoryInterface $repository) {}

    public function handle(productUnitUnitsearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}




