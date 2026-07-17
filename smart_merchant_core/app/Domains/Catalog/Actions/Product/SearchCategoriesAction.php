<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\DTOs\ProductsearchCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchProductsAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(ProductsearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}



