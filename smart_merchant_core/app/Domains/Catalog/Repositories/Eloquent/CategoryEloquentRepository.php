<?php

namespace App\Domains\Catalog\Repositories\Eloquent;

use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Models\Business;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\DTOs\CategoryListCriteriaDTO;
use App\Domains\Catalog\DTOs\CategoriesearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateCategoryDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class CategoryEloquentRepository implements CategoryRepositoryInterface
{
    public function create(array $data): Category
    {
        return Category::create($data);
    }

    public function findById(string $id): ?Category
    {
        return Category::find($id);
    }

    public function existsByName(string $name, string $businessId): bool
    {
        return Category::where('category_name', $name)->where('business_id', $businessId)->exists();
    }

    public function existsByCode(string $code, string $businessId): bool
    {
        return Category::where('category_code', strtoupper($code))->where('business_id', $businessId)->exists();
    }

    public function paginate(CategoryListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Category::where('business_id', $criteria->businessId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(CategoriesearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Category::where('business_id', $criteria->businessId);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('category_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('category_code', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        if ($criteria->parentId !== null) {
            if ($criteria->parentId === 'null') {
                $query->whereNull('parent_id');
            } else {
                $query->where('parent_id', $criteria->parentId);
            }
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Category $category, UpdateCategoryDTO $dto): Category
    {
        $category->update($dto->toArray());
        return $category;
    }

    public function delete(Category $category): bool
    {
        return (bool) $category->delete();
    }

    public function updateStatus(Category $category, bool $isActive): Category
    {
        $category->update(['is_active' => $isActive]);
        return $category;
    }

    public function isUsed(Category $category): bool
    {
        return \App\Domains\Catalog\Models\Product::where('category_id', $category->id)->exists()
            || Category::where('parent_id', $category->id)->exists();
    }
}





