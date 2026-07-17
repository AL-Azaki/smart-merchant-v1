<?php

namespace App\Domains\Catalog\Actions\BranchProductPrice;

use App\Domains\Catalog\DTOs\ViewBranchProductPriceDTO;
use App\Domains\Catalog\Models\BranchProductPrice;
use App\Domains\Catalog\Repositories\Contracts\BranchProductPriceRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewBranchProductPriceAction
{
    public function __construct(private readonly BranchProductPriceRepositoryInterface $repository) {}

    public function handle(ViewBranchProductPriceDTO $dto): BranchProductPrice
    {
        $branchProductPrice = $this->repository->findById($dto->id, ['branch', 'productUnit']);

        if (!$branchProductPrice || $branchProductPrice->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Branch Product Price not found.");
        }

        return $branchProductPrice;
    }
}
