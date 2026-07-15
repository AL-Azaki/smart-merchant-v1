<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ActivateUserAction
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

        if ($user->status === 'Active') {
            return $user;
        }

        return $this->repository->updateStatus($user, 'Active');
    }
}
