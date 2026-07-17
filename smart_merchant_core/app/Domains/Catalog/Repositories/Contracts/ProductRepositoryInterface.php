<?php

namespace App\Domains\Catalog\Repositories\Contracts;

use App\Domains\Catalog\Models\Product;

interface ProductRepositoryInterface
{
    public function create(array $data): Product;

    public function findById(string $id, array $with = []): ?Product;

    public function existsByCode(string $code, string $businessId): bool;

    public function paginate(\App\Domains\Catalog\DTOs\ProductListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Catalog\DTOs\ProductSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Product $product, \App\Domains\Catalog\DTOs\UpdateProductDTO $dto): Product;

    public function delete(Product $product): bool;

    public function updateStatus(Product $product, bool $isActive): Product;
}
