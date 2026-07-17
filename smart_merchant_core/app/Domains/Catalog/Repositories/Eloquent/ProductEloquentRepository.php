<?php

namespace App\Domains\Catalog\Repositories\Eloquent;

use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use App\Domains\Catalog\DTOs\ProductListCriteriaDTO;
use App\Domains\Catalog\DTOs\ProductSearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateProductDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductEloquentRepository implements ProductRepositoryInterface
{
    public function create(array $data): Product
    {
        return Product::create($data);
    }

    public function findById(string $id, array $with = []): ?Product
    {
        return Product::with($with)->find($id);
    }

    public function existsByCode(string $code, string $businessId): bool
    {
        return Product::where('product_code', strtoupper($code))->where('business_id', $businessId)->exists();
    }

    public function paginate(ProductListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Product::with(['primaryImage', 'baseUnit'])
            ->where('business_id', $criteria->businessId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(ProductSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Product::with(['primaryImage', 'baseUnit'])
            ->where('business_id', $criteria->businessId);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('product_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('product_code', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        if ($criteria->categoryId !== null) {
            $query->where('category_id', $criteria->categoryId);
        }

        if ($criteria->brandId !== null) {
            $query->where('brand_id', $criteria->brandId);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(Product $product, UpdateProductDTO $dto): Product
    {
        $product->update($dto->toArray());
        return $product;
    }

    public function delete(Product $product): bool
    {
        return (bool) $product->delete();
    }

    public function updateStatus(Product $product, bool $isActive): Product
    {
        $product->update(['is_active' => $isActive]);
        return $product;
    }
}
