<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;

class BranchEloquentRepository implements BranchRepositoryInterface
{
    public function create(array $data): Branch
    {
        return Branch::create($data);
    }

    public function findById(string $id): ?Branch
    {
        return Branch::find($id);
    }

    public function existsByCodeInBusiness(string $businessId, string $branchCode): bool
    {
        return Branch::where('business_id', $businessId)
            ->where('branch_code', $branchCode)
            ->exists();
    }

    public function findByIdWithRelations(string $id, array $relations = []): ?Branch
    {
        return Branch::with($relations)->find($id);
    }

    public function paginate(\App\Domains\Core\DTOs\BranchListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        return Branch::where('business_id', $criteria->businessId)
            ->with($criteria->includes)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(\App\Domains\Core\DTOs\BranchSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        $query = Branch::where('business_id', $criteria->businessId)
            ->with($criteria->includes);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('branch_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('branch_code', 'like', "%{$criteria->keyword}%")
                  ->orWhere('email', 'like', "%{$criteria->keyword}%")
                  ->orWhere('phone', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        if ($criteria->isDefault !== null) {
            $query->where('is_default', $criteria->isDefault);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Branch $branch, \App\Domains\Core\DTOs\UpdateBranchDTO $dto): Branch
    {
        $branch->update($dto->toArray());
        return $branch;
    }

    public function removeDefaultForBusiness(string $businessId): void
    {
        Branch::where('business_id', $businessId)->update(['is_default' => false]);
    }

    public function setAsDefault(Branch $branch): Branch
    {
        $branch->update(['is_default' => true]);
        return $branch;
    }

    public function updateStatus(Branch $branch, bool $isActive): Branch
    {
        $branch->update(['is_active' => $isActive]);
        return $branch;
    }

    public function countByBusiness(string $businessId): int
    {
        return Branch::where('business_id', $businessId)->count();
    }

    public function delete(Branch $branch): bool
    {
        return (bool) $branch->delete();
    }
}
