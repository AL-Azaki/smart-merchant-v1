<?php

namespace App\Domains\Finance\Services\Banking;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use RuntimeException;

class BankAccountResolver
{
    private BankAccountRepositoryInterface $repository;

    public function __construct(BankAccountRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    /**
     * Resolves the appropriate active BankAccount for a given ID.
     * Validates that the account is Active and belongs to the correct business.
     */
    public function resolve(string $bankAccountId, string $businessId): BankAccount
    {
        $account = $this->repository->findById($bankAccountId);

        if (! $account) {
            throw new RuntimeException("BankAccount [{$bankAccountId}] not found.");
        }

        if ($account->status === 'Closed') {
            throw new RuntimeException(
                "BankAccount \"{$account->display_name}\" is Closed. No transactions are permitted."
            );
        }

        if ($account->business_id !== $businessId) {
            throw new RuntimeException(
                "BankAccount does not belong to the specified Business."
            );
        }

        return $account;
    }
}
