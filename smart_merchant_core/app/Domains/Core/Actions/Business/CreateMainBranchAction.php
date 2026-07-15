<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;

class CreateMainBranchAction
{
    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(Business $business): Branch
    {
        return $this->repository->create([
            'business_id' => $business->id,
            'branch_name' => 'Main Branch',
            'branch_code' => 'MAIN-001',
            'phone'       => $business->primary_phone,
            'email'       => $business->primary_email,
            'is_default'  => true,
            'is_active'   => true,
        ]);
    }
}
