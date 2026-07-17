<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class ActivateProductAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(Product $Product): Product
    {
        if ($Product->is_active) {
            return $Product;
        }

        return $this->repository->updateStatus($Product, true);
    }
}





