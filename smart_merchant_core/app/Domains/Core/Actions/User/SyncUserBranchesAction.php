<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;

class SyncUserBranchesAction
{
    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(User $user, array $branchIds): void
    {
        // Business Rule: Could validate if branches exist and belong to business
        $this->repository->syncBranches($user, $branchIds);
    }
}
