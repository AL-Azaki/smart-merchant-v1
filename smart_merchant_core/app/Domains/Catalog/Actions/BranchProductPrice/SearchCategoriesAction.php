<?php

namespace App\Domains\Catalog\Actions\BranchbranchProductPricePrice;

use App\Domains\Catalog\DTOs\BranchbranchProductPricePricesearchCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\BranchbranchProductPricePriceRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchBranchbranchProductPricePricesAction
{
    public function __construct(private readonly BranchbranchProductPricePriceRepositoryInterface $repository) {}

    public function handle(BranchbranchProductPricePricesearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}




