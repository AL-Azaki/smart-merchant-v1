<?php

namespace App\Domains\Catalog\Actions\BranchProductPrice;

use App\Domains\Catalog\DTOs\CreateBranchProductPriceDTO;
use App\Domains\Catalog\Models\BranchProductPrice;
use App\Domains\Core\Models\Branch;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Catalog\Repositories\Contracts\BranchProductPriceRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class CreateBranchProductPriceAction
{
    public function __construct(private readonly BranchProductPriceRepositoryInterface $repository) {}

    public function handle(CreateBranchProductPriceDTO $dto): BranchProductPrice
    {
        $branch = Branch::find($dto->branchId);
        if (!$branch || $branch->business_id !== $dto->businessId) {
            throw new CatalogDomainException("Branch does not exist or does not belong to this business.");
        }

        $unit = ProductUnit::find($dto->productUnitId);
        if (!$unit || $unit->business_id !== $dto->businessId) {
            throw new CatalogDomainException("Product unit does not exist or does not belong to this business.");
        }

        if ($this->repository->exists($dto->branchId, $dto->productUnitId)) {
            throw new CatalogDomainException("Pricing already exists for this branch and product unit.");
        }
        
        if ($dto->purchasePrice < 0 || $dto->minimumPrice < 0) {
            throw new CatalogDomainException("Prices cannot be negative.");
        }
        
        if ($dto->sellingPrice < $dto->minimumPrice) {
            throw new CatalogDomainException("Selling price cannot be less than minimum price.");
        }

        return $this->repository->create($dto->toArray());
    }
}
