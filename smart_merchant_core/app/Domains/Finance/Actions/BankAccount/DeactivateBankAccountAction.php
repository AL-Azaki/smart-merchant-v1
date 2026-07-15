<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeactivateBankAccountAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(string $bankAccountId, string $businessId): BankAccount
    {
        $bankAccount = $this->repository->findById($bankAccountId);

        if (!$bankAccount || $bankAccount->business_id !== $businessId) {
            throw new ModelNotFoundException("Bank account not found.");
        }

        return $this->repository->update($bankAccount, ['is_active' => false]);
    }
}
