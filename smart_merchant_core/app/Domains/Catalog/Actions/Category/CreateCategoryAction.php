<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\DTOs\CreateCategoryDTO;
use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class CreateCategoryAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(CreateCategoryDTO $dto): Category
    {
        if ($this->repository->existsByName($dto->categoryName, $dto->businessId)) {
            throw new CatalogDomainException("Category name '{$dto->categoryName}' already exists.");
        }

        if ($dto->categoryCode && $this->repository->existsByCode($dto->categoryCode, $dto->businessId)) {
            throw new CatalogDomainException("Category code '{$dto->categoryCode}' already exists.");
        }

        if ($dto->parentId) {
            $parent = $this->repository->findById($dto->parentId);
            if (!$parent || $parent->business_id !== $dto->businessId) {
                throw new CatalogDomainException("Parent category does not exist or does not belong to this business.");
            }
        }

        return $this->repository->create($dto->toArray());
    }
}
