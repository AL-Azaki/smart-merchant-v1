<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\DTOs\CategoriesearchCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchCategoriesAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(CategoriesearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}


