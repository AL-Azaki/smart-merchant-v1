<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\DTOs\CreateUserDTO;
use Illuminate\Support\Facades\DB;
use Throwable;

class CreateUserAction
{
    public function __construct(
        private readonly CreateUserRecordAction $createUserRecord,
        private readonly SyncUserRolesAction $syncUserRoles,
        private readonly SyncUserBranchesAction $syncUserBranches
    ) {}

    /**
     * @throws Throwable
     */
    public function handle(CreateUserDTO $dto): User
    {
        return DB::transaction(function () use ($dto) {
            $user = $this->createUserRecord->handle(
                businessId: $dto->businessId,
                fullName: $dto->fullName,
                username: $dto->username,
                email: $dto->email,
                password: $dto->password,
                languageId: $dto->languageId,
                timezoneId: $dto->timezoneId
            );

            if (!empty($dto->roleIds)) {
                $this->syncUserRoles->handle($user, $dto->roleIds);
            }

            if (!empty($dto->branchIds)) {
                $this->syncUserBranches->handle($user, $dto->branchIds);
            }

            return $user;
        });
    }
}
