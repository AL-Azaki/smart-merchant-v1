<?php

namespace App\Domains\Catalog\Repositories\Eloquent;

use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Catalog\Repositories\Contracts\ProductUnitRepositoryInterface;
use App\Domains\Catalog\DTOs\ProductUnitListCriteriaDTO;
use App\Domains\Catalog\DTOs\ProductUnitSearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateProductUnitDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductUnitEloquentRepository implements ProductUnitRepositoryInterface
{
    public function create(array $data): ProductUnit
    {
        return ProductUnit::create($data);
    }

    public function findById(string $id, array $with = []): ?ProductUnit
    {
        return ProductUnit::with($with)->find($id);
    }

    public function existsBySku(string $sku, string $businessId): bool
    {
        return ProductUnit::where('sku', strtoupper($sku))->where('business_id', $businessId)->exists();
    }

    public function existsByBarcode(string $barcode, string $businessId): bool
    {
        return ProductUnit::where('barcode', $barcode)->where('business_id', $businessId)->exists();
    }
    
    public function hasBaseUnit(string $productId): bool
    {
        return ProductUnit::where('product_id', $productId)->where('is_base_unit', true)->exists();
    }
    
    public function unsetBaseUnit(string $productId): void
    {
        ProductUnit::where('product_id', $productId)->update(['is_base_unit' => false]);
    }

    public function paginate(ProductUnitListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return ProductUnit::with('unit')
            ->where('business_id', $criteria->businessId)
            ->where('product_id', $criteria->productId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(ProductUnitSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = ProductUnit::with('unit')
            ->where('business_id', $criteria->businessId);

        if ($criteria->productId !== null) {
            $query->where('product_id', $criteria->productId);
        }

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('sku', 'like', "%{$criteria->keyword}%")
                  ->orWhere('barcode', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(ProductUnit $productUnit, UpdateProductUnitDTO $dto): ProductUnit
    {
        $productUnit->update($dto->toArray());
        return $productUnit;
    }

    public function delete(ProductUnit $productUnit): bool
    {
        return (bool) $productUnit->delete();
    }

    public function updateStatus(ProductUnit $productUnit, bool $isActive): ProductUnit
    {
        $productUnit->update(['is_active' => $isActive]);
        return $productUnit;
    }
}
