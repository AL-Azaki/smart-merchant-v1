<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\DTOs\CreateChartOfAccountDTO;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\AccountTypeRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreateChartOfAccountAction
{
    public function __construct(
        private readonly ChartOfAccountRepositoryInterface $repository,
        private readonly AccountTypeRepositoryInterface $accountTypeRepository
    ) {}

    public function handle(CreateChartOfAccountDTO $dto): ChartOfAccount
    {
        // Validate Account Type exists
        $accountType = $this->accountTypeRepository->findById($dto->accountTypeId);
        if (!$accountType) {
            throw ValidationException::withMessages(['account_type_id' => 'Invalid account type.']);
        }

        // Validate Account Code uniqueness
        if ($dto->accountCode) {
            $existing = $this->repository->findByCode($dto->businessId, $dto->accountCode);
            if ($existing) {
                throw ValidationException::withMessages(['account_code' => 'Account code must be unique within the business.']);
            }
        }

        $accountLevel = 1;
        $parentAccountId = $dto->parentAccountId;

        // If it has a parent, validate parent
        if ($parentAccountId) {
            $parent = $this->repository->findById($parentAccountId);
            
            if (!$parent || $parent->business_id !== $dto->businessId) {
                throw ValidationException::withMessages(['parent_account_id' => 'Invalid parent account.']);
            }

            // Inherit account type from parent
            if ($parent->account_type_id !== $dto->accountTypeId) {
                throw ValidationException::withMessages(['account_type_id' => 'Child account must have the same account type as its parent.']);
            }

            $accountLevel = $parent->account_level + 1;
        }

        // Prepare data for creation
        $data = [
            'business_id' => $dto->businessId,
            'account_type_id' => $dto->accountTypeId,
            'account_name' => $dto->accountName,
            'normal_balance' => $dto->normalBalance,
            'account_code' => $dto->accountCode,
            'parent_account_id' => $parentAccountId,
            'currency_id' => $dto->currencyId,
            'description' => $dto->description,
            'account_category' => $dto->accountCategory,
            'allow_posting' => $dto->allowPosting,
            'is_system' => $dto->isSystem,
            'is_active' => $dto->isActive,
            'account_level' => $accountLevel,
        ];

        return $this->repository->create($data);
    }
}
