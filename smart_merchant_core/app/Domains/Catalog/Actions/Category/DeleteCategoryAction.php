<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class DeleteCategoryAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(Category $category): void
    {
        if ($this->repository->isUsed($category)) {
            throw new CatalogDomainException("Cannot delete Category because it is used by products or has subcategories. Please deactivate it instead.");
        }

        $this->repository->delete($category);
    }
}

