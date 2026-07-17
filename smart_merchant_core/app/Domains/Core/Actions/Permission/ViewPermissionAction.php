<?php

namespace App\Domains\Core\Actions\Permission;

use App\Domains\Core\Models\Permission;
use App\Domains\Core\DTOs\ViewPermissionDTO;
use App\Domains\Core\Repositories\Contracts\PermissionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewPermissionAction
{
    public function __construct(private readonly PermissionRepositoryInterface $repository) {}

    public function handle(ViewPermissionDTO $dto): Permission
    {
        $permission = $this->repository->findById($dto->permissionId);

        if (!$permission) {
            throw new CoreDomainException("The specified permission does not exist.");
        }

        // Note: No Tenant Isolation required. Permission is a System Catalog.
        
        return $permission;
    }
}
