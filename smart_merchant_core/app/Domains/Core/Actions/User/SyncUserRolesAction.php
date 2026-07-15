<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;

class SyncUserRolesAction
{
    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(User $user, array $roleIds): void
    {
        // Business Rule: Could validate if roles exist and belong to business
        // Skipping complex validation for now assuming IDs are valid from request/frontend
        // In a strict setup, RoleRepository should verify them.
        
        $this->repository->syncRoles($user, $roleIds);
    }
}
