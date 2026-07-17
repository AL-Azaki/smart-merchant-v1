<?php

namespace App\Domains\Core\Actions\Account;

use App\Domains\Core\Models\Account;
use App\Domains\Core\DTOs\UpdateAccountDTO;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdateAccountAction
{
    public function __construct(private readonly AccountRepositoryInterface $repository) {}

    public function handle(string $accountId, UpdateAccountDTO $dto): Account
    {
        $account = $this->repository->findById($accountId);

        if (!$account) {
            throw new CoreDomainException("The specified account does not exist.");
        }

        if ($dto->email !== null && $dto->email !== $account->email) {
            if ($this->repository->existsByEmail($dto->email)) {
                throw new CoreDomainException("The email '{$dto->email}' is already in use by another account.");
            }
        }

        return $this->repository->update($account, $dto);
    }
}
