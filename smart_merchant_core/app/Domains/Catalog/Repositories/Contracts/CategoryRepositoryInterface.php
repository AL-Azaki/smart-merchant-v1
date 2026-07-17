<?php

namespace App\Domains\Catalog\Repositories\Contracts;

use App\Domains\Catalog\Models\Category;

interface CategoryRepositoryInterface
{
    public function create(array $data): Category;

    public function findById(string $id): ?Category;

    public function existsByName(string $name, string $businessId): bool;

    public function existsByCode(string $code, string $businessId): bool;

    public function paginate(\App\Domains\Catalog\DTOs\CategoryListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Catalog\DTOs\CategoriesearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Category $category, \App\Domains\Catalog\DTOs\UpdateCategoryDTO $dto): Category;

    public function delete(Category $category): bool;

    public function updateStatus(Category $category, bool $isActive): Category;

    public function isUsed(Category $category): bool;
}






