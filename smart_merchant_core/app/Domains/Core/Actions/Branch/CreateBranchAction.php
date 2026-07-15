<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\DTOs\CreateBranchDTO;
use App\Domains\Core\Actions\Business\CreatePrintSettingsAction;
use Illuminate\Support\Facades\DB;
use Throwable;

class CreateBranchAction
{
    public function __construct(
        private readonly ValidateBusinessStateAction $validateBusinessState,
        private readonly CreateBranchRecordAction $createBranchRecord,
        private readonly CreatePrintSettingsAction $createPrintSettings
    ) {}

    /**
     * Orchestrates the branch creation flow.
     * Throws an exception on any failure, automatically rolling back the transaction.
     *
     * @param CreateBranchDTO $dto
     * @return Branch
     * @throws Throwable
     */
    public function handle(CreateBranchDTO $dto): Branch
    {
        return DB::transaction(function () use ($dto) {
            
            $this->validateBusinessState->handle($dto->businessId);

            $branch = $this->createBranchRecord->handle(
                businessId: $dto->businessId,
                branchName: $dto->branchName,
                branchCode: $dto->branchCode,
                phone: $dto->phone,
                email: $dto->email,
                address: $dto->address,
                isActive: $dto->isActive
            );

            $this->createPrintSettings->handle($dto->businessId, $branch->id);

            return $branch;
        });
    }
}
