<?php

namespace App\Domains\Catalog\Repositories\Contracts;

use App\Domains\Catalog\Models\ProductImage;

interface ProductImageRepositoryInterface
{
    public function create(array $data): ProductImage;

    public function findById(string $id, array $with = []): ?ProductImage;

    public function hasPrimaryImage(string $productId): bool;

    public function unsetPrimaryImage(string $productId): void;

    public function paginate(\App\Domains\Catalog\DTOs\ProductImageListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Catalog\DTOs\ProductImageSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(ProductImage $productImage, \App\Domains\Catalog\DTOs\UpdateProductImageDTO $dto): ProductImage;

    public function delete(ProductImage $productImage): bool;
}
