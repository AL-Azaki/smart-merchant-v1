<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class SuspendUserAction
{
    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(string $userId, string $businessId): User
    {
        $user = $this->repository->findById($userId);

        if (!$user) {
            throw new CoreDomainException("The specified user does not exist.");
        }

        if ($user->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified user.");
        }

        // Business Rule: Can we suspend the owner? Usually no, but we don't have is_owner flag yet.
        // That will be checked by policy or another rule if implemented.

        if ($user->status === 'Suspended') {
            return $user;
        }

        return $this->repository->updateStatus($user, 'Suspended');
    }
}
