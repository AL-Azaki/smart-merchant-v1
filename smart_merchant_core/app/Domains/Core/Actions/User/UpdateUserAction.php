<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\DTOs\UpdateUserDTO;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdateUserAction
{
    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(string $userId, string $businessId, UpdateUserDTO $dto): User
    {
        $user = $this->repository->findById($userId);

        if (!$user) {
            throw new CoreDomainException("The specified user does not exist.");
        }

        if ($user->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified user.");
        }

        if ($dto->username !== null && $dto->username !== $user->username) {
            if ($this->repository->existsByUsernameInBusiness($businessId, $dto->username)) {
                throw new CoreDomainException("The username '{$dto->username}' is already taken in this business.");
            }
        }

        return $this->repository->update($user, $dto);
    }
}
