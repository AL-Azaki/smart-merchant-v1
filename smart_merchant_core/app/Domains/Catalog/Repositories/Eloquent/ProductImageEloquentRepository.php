<?php

namespace App\Domains\Catalog\Repositories\Eloquent;

use App\Domains\Catalog\Models\ProductImage;
use App\Domains\Catalog\Repositories\Contracts\ProductImageRepositoryInterface;
use App\Domains\Catalog\DTOs\ProductImageListCriteriaDTO;
use App\Domains\Catalog\DTOs\ProductImageSearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateProductImageDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductImageEloquentRepository implements ProductImageRepositoryInterface
{
    public function create(array $data): ProductImage
    {
        return ProductImage::create($data);
    }

    public function findById(string $id, array $with = []): ?ProductImage
    {
        return ProductImage::with($with)->find($id);
    }

    public function hasPrimaryImage(string $productId): bool
    {
        return ProductImage::where('product_id', $productId)->where('is_primary', true)->exists();
    }

    public function unsetPrimaryImage(string $productId): void
    {
        ProductImage::where('product_id', $productId)->update(['is_primary' => false]);
    }

    public function paginate(ProductImageListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return ProductImage::where('product_id', $criteria->productId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(ProductImageSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = ProductImage::where('product_id', $criteria->productId);

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(ProductImage $productImage, UpdateProductImageDTO $dto): ProductImage
    {
        $productImage->update($dto->toArray());
        return $productImage;
    }

    public function delete(ProductImage $productImage): bool
    {
        return (bool) $productImage->delete();
    }
}
