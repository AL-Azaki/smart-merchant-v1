<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class DeactivateCategoryAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(Category $category): Category
    {

        if (!$category->is_active) {
            return $category;
        }

        return $this->repository->updateStatus($category, false);
    }
}




