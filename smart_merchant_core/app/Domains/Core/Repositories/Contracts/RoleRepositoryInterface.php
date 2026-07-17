<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\Role;

interface RoleRepositoryInterface
{
    public function create(array $data): Role;
    
    public function findById(string $id): ?Role;
    
    public function existsByNameInBusiness(string $businessId, string $name): bool;
    
    public function findByIdWithRelations(string $id, array $relations = []): ?Role;
    
    public function paginate(\App\Domains\Core\DTOs\RoleListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;
    
    public function search(\App\Domains\Core\DTOs\RoleSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;
    
    public function update(Role $role, \App\Domains\Core\DTOs\UpdateRoleDTO $dto): Role;
    
    public function delete(Role $role): bool;
    
    public function syncPermissions(Role $role, array $permissionIds): void;
    
    public function hasUsers(Role $role): bool;
}
