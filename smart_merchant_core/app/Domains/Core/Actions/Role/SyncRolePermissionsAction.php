<?php

namespace App\Domains\Core\Actions\Role;

use App\Domains\Core\Models\Role;
use App\Domains\Core\DTOs\SyncRolePermissionsDTO;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\PermissionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class SyncRolePermissionsAction
{
    public function __construct(
        private readonly RoleRepositoryInterface $roleRepository,
        private readonly PermissionRepositoryInterface $permissionRepository
    ) {}

    public function handle(SyncRolePermissionsDTO $dto): Role
    {
        $role = $this->roleRepository->findById($dto->roleId);

        if (!$role) {
            throw new CoreDomainException("The specified role does not exist.");
        }

        if ($role->business_id !== $dto->businessId) {
            throw new CoreDomainException("Unauthorized access to the specified role.");
        }

        if ($role->is_system) {
            throw new CoreDomainException("System roles cannot have their permissions modified.");
        }

        // Validate all permission IDs exist in the System Catalog
        if (!$this->permissionRepository->existsAll($dto->permissionIds)) {
            throw new CoreDomainException("One or more provided permission IDs are invalid.");
        }

        $this->roleRepository->syncPermissions($role, $dto->permissionIds);

        return $role;
    }
}
