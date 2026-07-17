<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\DTOs\CategoryListCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListCategoriesAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(CategoryListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}


