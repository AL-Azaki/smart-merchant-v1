<?php

namespace App\Domains\Catalog\Actions\productUnitUnit;

use App\Domains\Catalog\Models\productUnitUnit;
use App\Domains\Catalog\Repositories\Contracts\productUnitUnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class ActivateproductUnitUnitAction
{
    public function __construct(private readonly productUnitUnitRepositoryInterface $repository) {}

    public function handle(productUnitUnit $productUnitUnit): productUnitUnit
    {
        if ($productUnitUnit->is_active) {
            return $productUnitUnit;
        }

        return $this->repository->updateStatus($productUnitUnit, true);
    }
}






