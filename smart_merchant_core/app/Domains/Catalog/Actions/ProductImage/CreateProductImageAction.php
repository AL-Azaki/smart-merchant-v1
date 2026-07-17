<?php

namespace App\Domains\Catalog\Actions\ProductImage;

use App\Domains\Catalog\DTOs\CreateProductImageDTO;
use App\Domains\Catalog\Models\ProductImage;
use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Repositories\Contracts\ProductImageRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class CreateProductImageAction
{
    public function __construct(private readonly ProductImageRepositoryInterface $repository) {}

    public function handle(CreateProductImageDTO $dto, string $businessId): ProductImage
    {
        $product = Product::find($dto->productId);
        if (!$product || $product->business_id !== $businessId) {
            throw new CatalogDomainException("Product does not exist or does not belong to this business.");
        }

        if ($dto->isPrimary) {
            $this->repository->unsetPrimaryImage($dto->productId);
        } else {
            if (!$this->repository->hasPrimaryImage($dto->productId)) {
                $dto = new CreateProductImageDTO(
                    productId: $dto->productId,
                    imagePath: $dto->imagePath,
                    isPrimary: true
                );
            }
        }

        return $this->repository->create($dto->toArray());
    }
}
