<?php

namespace App\Domains\Catalog\Actions\ProductImage;

use App\Domains\Catalog\DTOs\ViewProductImageDTO;
use App\Domains\Catalog\Models\ProductImage;
use App\Domains\Catalog\Repositories\Contracts\ProductImageRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewProductImageAction
{
    public function __construct(private readonly ProductImageRepositoryInterface $repository) {}

    public function handle(ViewProductImageDTO $dto): ProductImage
    {
        $productImage = $this->repository->findById($dto->id, ['product']);

        if (!$productImage || $productImage->product->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Product Image not found.");
        }

        return $productImage;
    }
}
