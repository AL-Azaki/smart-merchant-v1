<?php

namespace App\Domains\Catalog\Actions\ProductUnit;

use App\Domains\Catalog\DTOs\ViewProductUnitDTO;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Catalog\Repositories\Contracts\ProductUnitRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewProductUnitAction
{
    public function __construct(private readonly ProductUnitRepositoryInterface $repository) {}

    public function handle(ViewProductUnitDTO $dto): ProductUnit
    {
        $productUnit = $this->repository->findById($dto->id, ['unit']);

        if (!$productUnit || $productUnit->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Product Unit not found.");
        }

        return $productUnit;
    }
}
