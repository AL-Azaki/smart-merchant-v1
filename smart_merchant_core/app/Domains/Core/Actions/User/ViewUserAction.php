<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\DTOs\ViewUserDTO;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewUserAction
{
    private const ALLOWED_INCLUDES = ['roles', 'branches', 'business'];

    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(ViewUserDTO $dto, string $businessId): User
    {
        $validIncludes = array_intersect($dto->includes, self::ALLOWED_INCLUDES);

        $user = $this->repository->findByIdWithRelations($dto->userId, $validIncludes);

        if (!$user) {
            throw new CoreDomainException("The specified user does not exist.");
        }

        if ($user->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified user.");
        }

        return $user;
    }
}
