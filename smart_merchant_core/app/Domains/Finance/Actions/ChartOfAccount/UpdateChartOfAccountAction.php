<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\DTOs\UpdateChartOfAccountDTO;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdateChartOfAccountAction
{
    public function __construct(
        private readonly ChartOfAccountRepositoryInterface $repository
    ) {}

    public function handle(UpdateChartOfAccountDTO $dto): ChartOfAccount
    {
        $account = $this->repository->findById($dto->accountId);

        if (!$account || $account->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Account not found.");
        }

        // Validate Account Code uniqueness if changing
        if ($dto->accountCode && $dto->accountCode !== $account->account_code) {
            // Cannot change code if account has been used in journal lines
            if ($this->repository->hasJournalLines($account->id)) {
                throw ValidationException::withMessages(['account_code' => 'Cannot change account code after it has been used in journal entries.']);
            }

            $existing = $this->repository->findByCode($dto->businessId, $dto->accountCode);
            if ($existing) {
                throw ValidationException::withMessages(['account_code' => 'Account code must be unique within the business.']);
            }
        }

        $accountLevel = $account->account_level;
        $parentAccountId = $dto->parentAccountId;

        // Moving account in tree logic
        if ($parentAccountId !== $account->parent_account_id) {
            if ($this->repository->hasJournalLines($account->id)) {
                throw ValidationException::withMessages(['parent_account_id' => 'Cannot move account that has journal entry lines.']);
            }

            if ($this->repository->countChildren($account->id) > 0) {
                throw ValidationException::withMessages(['parent_account_id' => 'Cannot move account that has child accounts.']);
            }

            if ($parentAccountId) {
                $parent = $this->repository->findById($parentAccountId);
                
                if (!$parent || $parent->business_id !== $dto->businessId) {
                    throw ValidationException::withMessages(['parent_account_id' => 'Invalid parent account.']);
                }

                // Check type consistency
                if ($parent->account_type_id !== $account->account_type_id) {
                    throw ValidationException::withMessages(['parent_account_id' => 'Cannot move to a parent with a different account type.']);
                }

                // Circular reference check
                if ($parent->id === $account->id) {
                    throw ValidationException::withMessages(['parent_account_id' => 'An account cannot be its own parent.']);
                }

                $accountLevel = $parent->account_level + 1;
            } else {
                $accountLevel = 1; // Moved to root
            }
        }

        $data = [
            'account_name' => $dto->accountName,
            'description' => $dto->description,
            'is_active' => $dto->isActive,
            'account_level' => $accountLevel,
            'parent_account_id' => $parentAccountId,
        ];

        if ($dto->accountCode) {
            $data['account_code'] = $dto->accountCode;
        }

        return $this->repository->update($account, $data);
    }
}
