<?php

namespace App\Domains\Core\Actions\Role;

use App\Domains\Core\Models\Role;
use App\Domains\Core\DTOs\UpdateRoleDTO;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdateRoleAction
{
    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(string $roleId, string $businessId, UpdateRoleDTO $dto): Role
    {
        $role = $this->repository->findById($roleId);

        if (!$role) {
            throw new CoreDomainException("The specified role does not exist.");
        }

        if ($role->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified role.");
        }

        if ($role->is_system) {
            throw new CoreDomainException("System roles cannot be updated.");
        }

        if ($dto->name !== null && $dto->name !== $role->name) {
            if ($this->repository->existsByNameInBusiness($businessId, $dto->name)) {
                throw new CoreDomainException("A role with the name '{$dto->name}' already exists in this business.");
            }
        }

        return $this->repository->update($role, $dto);
    }
}
