<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\DTOs\UpdateBankAccountDTO;
use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;

class UpdateBankAccountAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(UpdateBankAccountDTO $dto): BankAccount
    {
        return DB::transaction(function () use ($dto) {
            $bankAccount = $this->repository->findById($dto->bankAccountId);

            if (!$bankAccount || $bankAccount->business_id !== $dto->businessId) {
                throw new ModelNotFoundException("Bank account not found.");
            }

            // Check immutability if used
            if ($this->repository->isUsedInOperations($bankAccount->id)) {
                if (
                    $bankAccount->currency_id !== $dto->currencyId ||
                    $bankAccount->branch_id !== $dto->branchId ||
                    $bankAccount->account_number !== $dto->accountNumber ||
                    $bankAccount->iban !== $dto->iban ||
                    $bankAccount->bank_name !== $dto->bankName
                ) {
                    throw ValidationException::withMessages([
                        'id' => 'Cannot modify core bank account details (currency, branch, account number, iban, bank name) because it is already used in operations.'
                    ]);
                }
            }

            // Uniqueness checks if changed
            if ($bankAccount->account_number !== $dto->accountNumber) {
                $existing = $this->repository->findByAccountNumber($dto->businessId, $dto->accountNumber);
                if ($existing) {
                    throw ValidationException::withMessages([
                        'account_number' => 'A bank account with this number already exists.'
                    ]);
                }
            }

            if ($dto->iban && $bankAccount->iban !== $dto->iban) {
                $existingIban = $this->repository->findByIban($dto->businessId, $dto->iban);
                if ($existingIban) {
                    throw ValidationException::withMessages([
                        'iban' => 'A bank account with this IBAN already exists.'
                    ]);
                }
            }

            if ($dto->isDefault && !$bankAccount->is_default) {
                $this->repository->removeDefaultForCurrency($dto->businessId, $dto->currencyId);
            }

            $data = [
                'currency_id' => $dto->currencyId,
                'branch_id' => $dto->branchId,
                'account_number' => $dto->accountNumber,
                'iban' => $dto->iban,
                'bank_name' => $dto->bankName,
                'display_name' => $dto->displayName,
                'description' => $dto->description,
                'is_default' => $dto->isDefault,
            ];

            return $this->repository->update($bankAccount, $data);
        });
    }
}
