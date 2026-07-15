<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;
use Illuminate\Support\Facades\Hash;

class CreateUserRecordAction
{
    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(
        string $businessId,
        string $fullName,
        string $username,
        string $email,
        string $password,
        ?string $languageId,
        ?string $timezoneId
    ): User {
        if ($this->repository->existsByEmail($email)) {
            throw new CoreDomainException("The email '{$email}' is already registered.");
        }

        if ($this->repository->existsByUsernameInBusiness($businessId, $username)) {
            throw new CoreDomainException("The username '{$username}' is already taken in this business.");
        }

        return $this->repository->create([
            'business_id' => $businessId,
            'full_name'   => $fullName,
            'username'    => $username,
            'email'       => $email,
            'password'    => Hash::make($password),
            'status'      => 'Active',
            'language_id' => $languageId,
            'timezone_id' => $timezoneId,
        ]);
    }
}
