<?php

namespace App\Domains\Catalog\Repositories\Eloquent;

use App\Domains\Catalog\Models\Unit;
use App\Domains\Catalog\Models\Business;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\DTOs\UnitListCriteriaDTO;
use App\Domains\Catalog\DTOs\UnitSearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateUnitDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class UnitEloquentRepository implements UnitRepositoryInterface
{
    public function create(array $data): Unit
    {
        return Unit::create($data);
    }

    public function findById(string $id): ?Unit
    {
        return Unit::find($id);
    }

    public function existsByCode(string $code, ?string $businessId = null): bool
    {
        $query = Unit::where('unit_symbol', strtoupper($code));
        if ($businessId) {
            $query->where('business_id', $businessId);
        }
        return $query->exists();
    }

    public function paginate(UnitListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Unit::where('business_id', $criteria->businessId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(UnitSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Unit::where('business_id', $criteria->businessId);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('unit_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('unit_symbol', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Unit $unit, UpdateUnitDTO $dto): Unit
    {
        $unit->update($dto->toArray());
        return $unit;
    }

    public function delete(Unit $unit): bool
    {
        return (bool) $unit->delete();
    }

    public function updateStatus(Unit $unit, bool $isActive): Unit
    {
        $unit->update(['is_active' => $isActive]);
        return $unit;
    }

    

    public function isUsed(Unit $unit): bool
    {
        return \App\Domains\Catalog\Models\ProductUnit::where('unit_id', $unit->id)->exists();
    }
}

