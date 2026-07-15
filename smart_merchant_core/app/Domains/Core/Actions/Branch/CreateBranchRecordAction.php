<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateBranchRecordAction
{
    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(
        string $businessId,
        string $branchName,
        string $branchCode,
        ?string $phone,
        ?string $email,
        ?string $address,
        bool $isActive
    ): Branch {
        if ($this->repository->existsByCodeInBusiness($businessId, $branchCode)) {
            throw new CoreDomainException("A branch with code '{$branchCode}' already exists for this business.");
        }

        return $this->repository->create([
            'business_id' => $businessId,
            'branch_name' => $branchName,
            'branch_code' => $branchCode,
            'phone'       => $phone,
            'email'       => $email,
            'address'     => $address,
            'is_default'  => false, // Handled separately by SetDefaultBranch
            'is_active'   => $isActive,
        ]);
    }
}
