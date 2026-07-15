<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\DTOs\CreateBankAccountDTO;
use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\DB;

class CreateBankAccountAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(CreateBankAccountDTO $dto): BankAccount
    {
        return DB::transaction(function () use ($dto) {
            $existingAcc = $this->repository->findByAccountNumber($dto->businessId, $dto->accountNumber);
            if ($existingAcc) {
                throw ValidationException::withMessages([
                    'account_number' => 'A bank account with this number already exists.'
                ]);
            }

            if ($dto->iban) {
                $existingIban = $this->repository->findByIban($dto->businessId, $dto->iban);
                if ($existingIban) {
                    throw ValidationException::withMessages([
                        'iban' => 'A bank account with this IBAN already exists.'
                    ]);
                }
            }

            if ($dto->isDefault) {
                $this->repository->removeDefaultForCurrency($dto->businessId, $dto->currencyId);
            }

            $data = [
                'business_id' => $dto->businessId,
                'branch_id' => $dto->branchId,
                'currency_id' => $dto->currencyId,
                'account_number' => $dto->accountNumber,
                'iban' => $dto->iban,
                'bank_name' => $dto->bankName,
                'display_name' => $dto->displayName,
                'description' => $dto->description,
                'is_active' => $dto->isActive,
                'is_default' => $dto->isDefault,
            ];

            return $this->repository->create($data);
        });
    }
}
