<?php

namespace App\Domains\Core\Actions\Account;

use App\Models\Core\Account;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CloseAccountAction
{
    public function __construct(private readonly AccountRepositoryInterface $repository) {}

    public function handle(string $accountId): Account
    {
        $account = $this->repository->findById($accountId);

        if (!$account) {
            throw new CoreDomainException("The specified account does not exist.");
        }

        if ($account->status === 'Closed') {
            return $account;
        }

        return $this->repository->updateStatus($account, 'Closed');
    }
}
