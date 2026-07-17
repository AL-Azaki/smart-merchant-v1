<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\Role;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\DTOs\RoleListCriteriaDTO;
use App\Domains\Core\DTOs\RoleSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateRoleDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class RoleEloquentRepository implements RoleRepositoryInterface
{
    public function create(array $data): Role
    {
        return Role::create($data);
    }

    public function findById(string $id): ?Role
    {
        return Role::find($id);
    }

    public function existsByNameInBusiness(string $businessId, string $name): bool
    {
        return Role::where('business_id', $businessId)
            ->where('name', $name)
            ->exists();
    }

    public function findByIdWithRelations(string $id, array $relations = []): ?Role
    {
        return Role::with($relations)->find($id);
    }

    public function paginate(RoleListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Role::where('business_id', $criteria->businessId)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(RoleSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Role::where('business_id', $criteria->businessId);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('description', 'like', "%{$criteria->keyword}%");
            });
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Role $role, UpdateRoleDTO $dto): Role
    {
        $role->update($dto->toArray());
        return $role;
    }

    public function delete(Role $role): bool
    {
        return (bool) $role->delete();
    }

    public function syncPermissions(Role $role, array $permissionIds): void
    {
        $role->permissions()->sync($permissionIds);
    }

    public function hasUsers(Role $role): bool
    {
        return $role->users()->exists();
    }

    public function createDefaultRoles(string $businessId): array
    {
        $roles = [
            Role::create([
                'business_id' => $businessId,
                'role_name' => 'Owner',
                'description' => 'System Owner with full access',
                'is_system_role' => true,
                'is_active' => true,
            ]),
            Role::create([
                'business_id' => $businessId,
                'role_name' => 'Manager',
                'description' => 'Store Manager',
                'is_system_role' => true,
                'is_active' => true,
            ]),
            Role::create([
                'business_id' => $businessId,
                'role_name' => 'Cashier',
                'description' => 'Point of Sale Cashier',
                'is_system_role' => true,
                'is_active' => true,
            ]),
        ];
        return $roles;
    }

    public function assignRoleToUser(string $userId, string $roleId): void
    {
        $user = \App\Domains\Core\Models\User::find($userId);
        if ($user) {
            $user->roles()->syncWithoutDetaching([$roleId]);
        }
    }
}
