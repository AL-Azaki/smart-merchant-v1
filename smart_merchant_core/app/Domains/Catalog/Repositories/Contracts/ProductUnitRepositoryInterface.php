<?php

namespace App\Domains\Catalog\Repositories\Contracts;

use App\Domains\Catalog\Models\ProductUnit;

interface ProductUnitRepositoryInterface
{
    public function create(array $data): ProductUnit;

    public function findById(string $id, array $with = []): ?ProductUnit;

    public function existsBySku(string $sku, string $businessId): bool;

    public function existsByBarcode(string $barcode, string $businessId): bool;
    
    public function hasBaseUnit(string $productId): bool;
    
    public function unsetBaseUnit(string $productId): void;

    public function paginate(\App\Domains\Catalog\DTOs\ProductUnitListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Catalog\DTOs\ProductUnitSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(ProductUnit $productUnit, \App\Domains\Catalog\DTOs\UpdateProductUnitDTO $dto): ProductUnit;

    public function delete(ProductUnit $productUnit): bool;

    public function updateStatus(ProductUnit $productUnit, bool $isActive): ProductUnit;
}
