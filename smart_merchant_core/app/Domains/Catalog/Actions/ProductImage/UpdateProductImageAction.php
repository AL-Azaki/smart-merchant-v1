<?php

namespace App\Domains\Catalog\Actions\ProductImage;

use App\Domains\Catalog\DTOs\UpdateProductImageDTO;
use App\Domains\Catalog\Models\ProductImage;
use App\Domains\Catalog\Repositories\Contracts\ProductImageRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class UpdateProductImageAction
{
    public function __construct(private readonly ProductImageRepositoryInterface $repository) {}

    public function handle(ProductImage $productImage, UpdateProductImageDTO $dto): ProductImage
    {
        if ($dto->isPrimary === true && !$productImage->is_primary) {
            $this->repository->unsetPrimaryImage($productImage->product_id);
        }
        
        if ($dto->isPrimary === false && $productImage->is_primary) {
            throw new CatalogDomainException("Cannot unset the primary image. You must set another image as the primary image instead.");
        }

        return $this->repository->update($productImage, $dto);
    }
}
