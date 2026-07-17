<?php

namespace App\Domains\Catalog\Actions\ProductUnit;

use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Catalog\Repositories\Contracts\ProductUnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class DeleteProductUnitAction
{
    public function __construct(private readonly ProductUnitRepositoryInterface $repository) {}

    public function handle(ProductUnit $productUnit): void
    {
        if ($productUnit->is_base_unit) {
            throw new CatalogDomainException("Cannot delete the base unit of a product.");
        }
        
        $this->repository->delete($productUnit);
    }
}
