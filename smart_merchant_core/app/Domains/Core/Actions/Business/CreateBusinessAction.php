<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;
use App\Domains\Core\DTOs\CreateBusinessDTO;
use Illuminate\Support\Facades\DB;
use Throwable;

class CreateBusinessAction
{
    public function __construct(
        private readonly CreateBusinessRecordAction $createBusinessRecord,
        private readonly CreateMainBranchAction $createMainBranch,
        private readonly CreateOwnerUserAction $createOwnerUser,
        private readonly AssignOwnerRoleAction $assignOwnerRole,
        private readonly CreateSubscriptionAction $createSubscription,
        private readonly CreateBusinessSettingsAction $createBusinessSettings,
        private readonly CreatePrintSettingsAction $createPrintSettings,
        private readonly InitializeChartOfAccountsAction $initializeChartOfAccounts,
        private readonly CreateFiscalYearAction $createFiscalYear,
        private readonly CreateDefaultTaxesAction $createDefaultTaxes
    ) {}

    /**
     * Orchestrates the business creation flow.
     * Throws an exception on any failure, automatically rolling back the transaction.
     *
     * @param CreateBusinessDTO $dto
     * @return Business
     * @throws Throwable
     */
    public function handle(CreateBusinessDTO $dto): Business
    {
        return DB::transaction(function () use ($dto) {
            
            $business = $this->createBusinessRecord->handle(
                accountId: $dto->accountId,
                businessName: $dto->businessName,
                businessType: $dto->businessType,
                primaryPhone: $dto->primaryPhone,
                primaryEmail: $dto->primaryEmail,
                logoPath: $dto->logoPath
            );

            $branch = $this->createMainBranch->handle($business);

            $ownerUser = $this->createOwnerUser->handle(
                accountId: $dto->accountId,
                branchId: $branch->id,
                username: $dto->ownerUsername,
                email: $dto->ownerEmail,
                password: $dto->ownerPassword,
                fullName: $dto->ownerName
            );

            $this->assignOwnerRole->handle($business->id, $ownerUser->id);

            $this->createSubscription->handle($business, $dto);

            $this->createBusinessSettings->handle($business, $dto->timezone);

            $this->createPrintSettings->handle($business->id, $branch->id);

            $this->initializeChartOfAccounts->handle($business->id);

            $this->createFiscalYear->handle($business->id);

            $this->createDefaultTaxes->handle($business->id);

            return $business;
        });
    }
}
