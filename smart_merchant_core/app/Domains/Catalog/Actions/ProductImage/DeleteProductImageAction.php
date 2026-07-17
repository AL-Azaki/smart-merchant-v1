<?php

namespace App\Domains\Catalog\Actions\ProductImage;

use App\Domains\Catalog\Models\ProductImage;
use App\Domains\Catalog\Repositories\Contracts\ProductImageRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class DeleteProductImageAction
{
    public function __construct(private readonly ProductImageRepositoryInterface $repository) {}

    public function handle(ProductImage $productImage): void
    {
        if ($productImage->is_primary) {
            throw new CatalogDomainException("Cannot delete the primary image of a product.");
        }
        
        $this->repository->delete($productImage);
    }
}
