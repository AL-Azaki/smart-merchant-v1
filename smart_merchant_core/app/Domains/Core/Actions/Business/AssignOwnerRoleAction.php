<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Role;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;

class AssignOwnerRoleAction
{
    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(string $businessId, string $userId): Role
    {
        $roles = $this->repository->createDefaultRoles($businessId);
        
        // Owner role is guaranteed to be the first one created based on repository implementation
        $ownerRole = $roles[0];
        
        $this->repository->assignRoleToUser($userId, $ownerRole->id);

        return $ownerRole;
    }
}
