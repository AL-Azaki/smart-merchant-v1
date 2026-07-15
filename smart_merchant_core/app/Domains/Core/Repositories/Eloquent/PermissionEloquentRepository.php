<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Models\Core\Permission;
use App\Domains\Core\Repositories\Contracts\PermissionRepositoryInterface;
use App\Domains\Core\DTOs\PermissionListCriteriaDTO;
use App\Domains\Core\DTOs\PermissionSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class PermissionEloquentRepository implements PermissionRepositoryInterface
{
    public function findById(string $id): ?Permission
    {
        return Permission::find($id);
    }

    public function paginate(PermissionListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Permission::orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(PermissionSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Permission::query();

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('group_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('description', 'like', "%{$criteria->keyword}%");
            });
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function existsAll(array $ids): bool
    {
        if (empty($ids)) return true;
        return Permission::whereIn('id', $ids)->count() === count(array_unique($ids));
    }
}
