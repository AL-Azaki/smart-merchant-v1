<?php

namespace App\Domains\Catalog\Actions\BranchbranchProductPricePrice;

use App\Domains\Catalog\Models\BranchbranchProductPricePrice;
use App\Domains\Catalog\Repositories\Contracts\BranchbranchProductPricePriceRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class DeactivateBranchbranchProductPricePriceAction
{
    public function __construct(private readonly BranchbranchProductPricePriceRepositoryInterface $repository) {}

    public function handle(BranchbranchProductPricePrice $BranchbranchProductPricePrice): BranchbranchProductPricePrice
    {

        if (!$BranchbranchProductPricePrice->is_active) {
            return $BranchbranchProductPricePrice;
        }

        return $this->repository->updateStatus($BranchbranchProductPricePrice, false);
    }
}






