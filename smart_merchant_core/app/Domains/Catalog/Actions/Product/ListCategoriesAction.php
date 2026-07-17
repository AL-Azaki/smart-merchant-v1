<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\DTOs\ProductListCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListProductsAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(ProductListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}



