<?php

namespace App\Domains\Core\Actions\Role;

use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class DeleteRoleAction
{
    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(string $roleId, string $businessId): void
    {
        $role = $this->repository->findById($roleId);

        if (!$role) {
            throw new CoreDomainException("The specified role does not exist.");
        }

        if ($role->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified role.");
        }

        if ($role->is_system) {
            throw new CoreDomainException("System roles cannot be deleted.");
        }

        if ($this->repository->hasUsers($role)) {
            throw new CoreDomainException("Cannot delete role because it is currently assigned to one or more users.");
        }

        $this->repository->delete($role);
    }
}
