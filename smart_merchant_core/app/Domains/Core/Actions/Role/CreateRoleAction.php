<?php

namespace App\Domains\Core\Actions\Role;

use App\Models\Core\Role;
use App\Domains\Core\DTOs\CreateRoleDTO;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateRoleAction
{
    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(CreateRoleDTO $dto): Role
    {
        if ($this->repository->existsByNameInBusiness($dto->businessId, $dto->name)) {
            throw new CoreDomainException("A role with the name '{$dto->name}' already exists in this business.");
        }

        return $this->repository->create([
            'business_id' => $dto->businessId,
            'name'        => $dto->name,
            'description' => $dto->description,
            'is_system'   => $dto->isSystem,
        ]);
    }
}
