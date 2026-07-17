<?php

namespace App\Domains\Catalog\Repositories\Contracts;

use App\Domains\Catalog\Models\BranchProductPrice;

interface BranchProductPriceRepositoryInterface
{
    public function create(array $data): BranchProductPrice;

    public function findById(string $id, array $with = []): ?BranchProductPrice;

    public function exists(string $branchId, string $productUnitId): bool;

    public function paginate(\App\Domains\Catalog\DTOs\BranchProductPriceListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Catalog\DTOs\BranchProductPriceSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(BranchProductPrice $branchProductPrice, \App\Domains\Catalog\DTOs\UpdateBranchProductPriceDTO $dto): BranchProductPrice;

    public function delete(BranchProductPrice $branchProductPrice): bool;

    public function updateStatus(BranchProductPrice $branchProductPrice, bool $isActive): BranchProductPrice;
}
