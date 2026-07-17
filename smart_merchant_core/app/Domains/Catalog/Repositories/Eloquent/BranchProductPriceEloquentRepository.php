<?php

namespace App\Domains\Catalog\Repositories\Eloquent;

use App\Domains\Catalog\Models\BranchProductPrice;
use App\Domains\Catalog\Repositories\Contracts\BranchProductPriceRepositoryInterface;
use App\Domains\Catalog\DTOs\BranchProductPriceListCriteriaDTO;
use App\Domains\Catalog\DTOs\BranchProductPriceSearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateBranchProductPriceDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class BranchProductPriceEloquentRepository implements BranchProductPriceRepositoryInterface
{
    public function create(array $data): BranchProductPrice
    {
        return BranchProductPrice::create($data);
    }

    public function findById(string $id, array $with = []): ?BranchProductPrice
    {
        return BranchProductPrice::with($with)->find($id);
    }

    public function exists(string $branchId, string $productUnitId): bool
    {
        return BranchProductPrice::where('branch_id', $branchId)->where('product_unit_id', $productUnitId)->exists();
    }

    public function paginate(BranchProductPriceListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return BranchProductPrice::with(['branch', 'productUnit'])
            ->where('business_id', $criteria->businessId)
            ->where('branch_id', $criteria->branchId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(BranchProductPriceSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = BranchProductPrice::with(['branch', 'productUnit'])
            ->where('business_id', $criteria->businessId);

        if ($criteria->branchId !== null) {
            $query->where('branch_id', $criteria->branchId);
        }

        if ($criteria->productUnitId !== null) {
            $query->where('product_unit_id', $criteria->productUnitId);
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(BranchProductPrice $branchProductPrice, UpdateBranchProductPriceDTO $dto): BranchProductPrice
    {
        $branchProductPrice->update($dto->toArray());
        return $branchProductPrice;
    }

    public function delete(BranchProductPrice $branchProductPrice): bool
    {
        return (bool) $branchProductPrice->delete();
    }

    public function updateStatus(BranchProductPrice $branchProductPrice, bool $isActive): BranchProductPrice
    {
        $branchProductPrice->update(['is_active' => $isActive]);
        return $branchProductPrice;
    }
}
