<?php

namespace App\Domains\Catalog\Actions\productUnitUnit;

use App\Domains\Catalog\DTOs\productUnitUnitListCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\productUnitUnitRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListproductUnitUnitsAction
{
    public function __construct(private readonly productUnitUnitRepositoryInterface $repository) {}

    public function handle(productUnitUnitListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}




