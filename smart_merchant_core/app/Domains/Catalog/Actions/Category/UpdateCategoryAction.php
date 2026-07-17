<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\DTOs\UpdateCategoryDTO;
use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class UpdateCategoryAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(Category $category, UpdateCategoryDTO $dto): Category
    {
        if ($dto->categoryName !== null && $dto->categoryName !== $category->category_name) {
            if ($this->repository->existsByName($dto->categoryName, $category->business_id)) {
                throw new CatalogDomainException("Category name '{$dto->categoryName}' already exists.");
            }
        }

        if ($dto->categoryCode !== null && $dto->categoryCode !== $category->category_code) {
            if ($this->repository->existsByCode($dto->categoryCode, $category->business_id)) {
                throw new CatalogDomainException("Category code '{$dto->categoryCode}' already exists.");
            }
        }

        if (array_key_exists('parent_id', $dto->toArray())) {
            if ($dto->parentId === $category->id) {
                throw new CatalogDomainException("A category cannot be its own parent.");
            }

            if ($dto->parentId) {
                $parent = $this->repository->findById($dto->parentId);
                if (!$parent || $parent->business_id !== $category->business_id) {
                    throw new CatalogDomainException("Parent category does not exist or does not belong to this business.");
                }

                // Check circular
                $currentParent = $parent;
                while ($currentParent) {
                    if ($currentParent->id === $category->id) {
                        throw new CatalogDomainException("Circular parent relationships are prohibited.");
                    }
                    $currentParent = $currentParent->parent_id ? $this->repository->findById($currentParent->parent_id) : null;
                }
            }
        }

        return $this->repository->update($category, $dto);
    }
}

