<?php

namespace App\Domains\Catalog\Actions\BranchProductPrice;

use App\Domains\Catalog\DTOs\UpdateBranchProductPriceDTO;
use App\Domains\Catalog\Models\BranchProductPrice;
use App\Domains\Catalog\Repositories\Contracts\BranchProductPriceRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class UpdateBranchProductPriceAction
{
    public function __construct(private readonly BranchProductPriceRepositoryInterface $repository) {}

    public function handle(BranchProductPrice $branchProductPrice, UpdateBranchProductPriceDTO $dto): BranchProductPrice
    {
        $purchase = $dto->purchasePrice ?? $branchProductPrice->purchase_price;
        $selling = $dto->sellingPrice ?? $branchProductPrice->selling_price;
        $min = $dto->minimumPrice ?? $branchProductPrice->minimum_price;
        
        if ($purchase < 0 || $min < 0) {
            throw new CatalogDomainException("Prices cannot be negative.");
        }
        if ($selling < $min) {
            throw new CatalogDomainException("Selling price cannot be less than minimum price.");
        }

        return $this->repository->update($branchProductPrice, $dto);
    }
}
