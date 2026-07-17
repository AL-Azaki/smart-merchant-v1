<?php

namespace App\Domains\Core\Actions\Account;

use App\Domains\Core\Models\Account;
use App\Domains\Core\DTOs\CreateAccountDTO;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateAccountAction
{
    public function __construct(private readonly AccountRepositoryInterface $repository) {}

    public function handle(CreateAccountDTO $dto): Account
    {
        if ($this->repository->existsByEmail($dto->email)) {
            throw new CoreDomainException("The email '{$dto->email}' is already in use by another account.");
        }

        $accountNumber = $dto->accountNumber ?? 'ACC-' . strtoupper(uniqid());

        if ($this->repository->existsByAccountNumber($accountNumber)) {
            throw new CoreDomainException("The account number '{$accountNumber}' is already in use.");
        }

        return $this->repository->create([
            'account_name'   => $dto->accountName,
            'account_number' => $accountNumber,
            'email'          => $dto->email,
            'phone'          => $dto->phone,
            'status'         => 'Active',
        ]);
    }
}
