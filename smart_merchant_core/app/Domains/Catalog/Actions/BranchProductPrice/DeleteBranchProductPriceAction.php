<?php

namespace App\Domains\Catalog\Actions\BranchProductPrice;

use App\Domains\Catalog\Models\BranchProductPrice;
use App\Domains\Catalog\Repositories\Contracts\BranchProductPriceRepositoryInterface;

class DeleteBranchProductPriceAction
{
    public function __construct(private readonly BranchProductPriceRepositoryInterface $repository) {}

    public function handle(BranchProductPrice $branchProductPrice): void
    {
        $this->repository->delete($branchProductPrice);
    }
}
