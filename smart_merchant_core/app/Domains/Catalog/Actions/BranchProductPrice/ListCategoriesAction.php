<?php

namespace App\Domains\Catalog\Actions\BranchbranchProductPricePrice;

use App\Domains\Catalog\DTOs\BranchbranchProductPricePriceListCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\BranchbranchProductPricePriceRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListBranchbranchProductPricePricesAction
{
    public function __construct(private readonly BranchbranchProductPricePriceRepositoryInterface $repository) {}

    public function handle(BranchbranchProductPricePriceListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}




