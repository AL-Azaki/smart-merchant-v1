<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\DTOs\ViewBankAccountDTO;
use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewBankAccountAction
{
    public function __construct(private readonly BankAccountRepositoryInterface $repository) {}

    public function handle(ViewBankAccountDTO $dto): BankAccount
    {
        $bankAccount = $this->repository->findById($dto->bankAccountId);

        if (!$bankAccount || $bankAccount->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Bank account not found.");
        }

        return $bankAccount;
    }
}
