<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;
use Illuminate\Support\Facades\Hash;

class CreateOwnerUserAction
{
    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(
        string $accountId,
        string $branchId,
        string $username,
        string $email,
        string $password,
        string $fullName
    ): User {
        if ($this->repository->existsByEmail($email)) {
            throw new CoreDomainException("User email '{$email}' is already registered.");
        }

        $user = $this->repository->create([
            'account_id'    => $accountId,
            'username'      => $username,
            'email'         => $email,
            'password_hash' => Hash::make($password),
            'full_name'     => $fullName,
            'is_active'     => true,
        ]);

        $this->repository->assignToBranch($user->id, $branchId);
        $this->repository->setDefaultBranch($user->id, $branchId);

        return $user;
    }
}
