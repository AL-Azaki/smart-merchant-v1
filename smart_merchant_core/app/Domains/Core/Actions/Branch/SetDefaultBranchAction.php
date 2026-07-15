<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;
use Illuminate\Support\Facades\DB;
use Throwable;

class SetDefaultBranchAction
{
    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    /**
     * @throws Throwable
     */
    public function handle(string $branchId, string $businessId): Branch
    {
        $branch = $this->repository->findById($branchId);

        if (!$branch) {
            throw new CoreDomainException("The specified branch does not exist.");
        }

        if ($branch->business_id !== $businessId) {
            throw new CoreDomainException("Unauthorized access to the specified branch.");
        }

        if (!$branch->is_active) {
            throw new CoreDomainException("Cannot set an inactive branch as default.");
        }

        if ($branch->is_default) {
            return $branch;
        }

        return DB::transaction(function () use ($branch, $businessId) {
            $this->repository->removeDefaultForBusiness($businessId);
            return $this->repository->setAsDefault($branch);
        });
    }
}
