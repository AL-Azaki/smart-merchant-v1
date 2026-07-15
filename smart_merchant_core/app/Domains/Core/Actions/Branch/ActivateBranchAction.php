<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ActivateBranchAction
{
    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(string $branchId, string $businessId): Branch
    {
        $branch = $this->repository->findById($branchId);

        if (!$branch) {
            throw new CoreDomainException("The specified branch does not exist.");
        }

        if ($branch->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified branch.");
        }

        if ($branch->is_active) {
            return $branch;
        }

        return $this->repository->updateStatus($branch, true);
    }
}
