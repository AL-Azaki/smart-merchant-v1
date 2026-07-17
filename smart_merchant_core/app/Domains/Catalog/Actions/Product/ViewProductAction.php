<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\DTOs\ViewProductDTO;
use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewProductAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(ViewProductDTO $dto): Product
    {
        $product = $this->repository->findById($dto->id, ['category', 'brand', 'tax', 'productUnits.unit', 'images']);

        if (!$product || $product->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Product not found.");
        }

        return $product;
    }
}
