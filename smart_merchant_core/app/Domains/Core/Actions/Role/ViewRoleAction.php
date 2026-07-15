<?php

namespace App\Domains\Core\Actions\Role;

use App\Models\Core\Role;
use App\Domains\Core\DTOs\ViewRoleDTO;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewRoleAction
{
    private const ALLOWED_INCLUDES = ['permissions'];

    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(ViewRoleDTO $dto, string $businessId): Role
    {
        $validIncludes = array_intersect($dto->includes, self::ALLOWED_INCLUDES);
        $role = $this->repository->findByIdWithRelations($dto->roleId, $validIncludes);

        if (!$role) {
            throw new CoreDomainException("The specified role does not exist.");
        }

        if ($role->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified role.");
        }

        return $role;
    }
}
