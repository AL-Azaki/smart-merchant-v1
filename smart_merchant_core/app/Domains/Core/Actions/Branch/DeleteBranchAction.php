<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class DeleteBranchAction
{
    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(string $branchId, string $businessId): void
    {
        $branch = $this->repository->findById($branchId);

        if (!$branch) {
            throw new CoreDomainException("The specified branch does not exist.");
        }

        if ($branch->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified branch.");
        }

        if ($branch->is_default) {
            throw new CoreDomainException("Cannot delete the default branch.");
        }

        if ($this->repository->countByBusiness($businessId) <= 1) {
            throw new CoreDomainException("Cannot delete the last branch in the business.");
        }

        // TODO: Check operational data (Sales, Purchases, Inventory, HR, Finance) before deleting
        // If operational data exists, throw CoreDomainException

        $this->repository->delete($branch);
    }
}
