<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteBankAccountAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(string $bankAccountId, string $businessId): bool
    {
        $bankAccount = $this->repository->findById($bankAccountId);

        if (!$bankAccount || $bankAccount->business_id !== $businessId) {
            throw new ModelNotFoundException("Bank account not found.");
        }

        if ($this->repository->isUsedInOperations($bankAccount->id)) {
            throw ValidationException::withMessages([
                'id' => 'Cannot delete a bank account that has been used in operations. Deactivate it instead.'
            ]);
        }

        return $this->repository->delete($bankAccount);
    }
}
