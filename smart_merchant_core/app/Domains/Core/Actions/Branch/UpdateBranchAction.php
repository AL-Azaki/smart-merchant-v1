<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\DTOs\UpdateBranchDTO;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdateBranchAction
{
    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(string $branchId, string $businessId, UpdateBranchDTO $dto): Branch
    {
        $branch = $this->repository->findById($branchId);

        if (!$branch) {
            throw new CoreDomainException("The specified branch does not exist.");
        }

        // Tenant Isolation Check
        if ($branch->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified branch.");
        }

        // Check unique branch code if it's being updated
        if ($dto->branchCode !== null && $dto->branchCode !== $branch->branch_code) {
            if ($this->repository->existsByCodeInBusiness($businessId, $dto->branchCode)) {
                throw new CoreDomainException("A branch with code '{$dto->branchCode}' already exists for this business.");
            }
        }

        return $this->repository->update($branch, $dto);
    }
}
