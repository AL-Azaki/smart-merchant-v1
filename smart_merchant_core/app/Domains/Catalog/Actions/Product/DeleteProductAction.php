<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;

class DeleteProductAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(Product $product): void
    {
        $this->repository->delete($product);
    }
}
