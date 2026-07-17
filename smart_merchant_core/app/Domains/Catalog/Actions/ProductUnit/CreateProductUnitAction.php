<?php

namespace App\Domains\Catalog\Actions\ProductUnit;

use App\Domains\Catalog\DTOs\CreateProductUnitDTO;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Models\Unit;
use App\Domains\Catalog\Repositories\Contracts\ProductUnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class CreateProductUnitAction
{
    public function __construct(private readonly ProductUnitRepositoryInterface $repository) {}

    public function handle(CreateProductUnitDTO $dto): ProductUnit
    {
        $product = Product::find($dto->productId);
        if (!$product || $product->business_id !== $dto->businessId) {
            throw new CatalogDomainException("Product does not exist or does not belong to this business.");
        }

        $unit = Unit::find($dto->unitId);
        if (!$unit || $unit->business_id !== $dto->businessId) {
            throw new CatalogDomainException("Unit does not exist or does not belong to this business.");
        }

        if ($dto->sku && $this->repository->existsBySku($dto->sku, $dto->businessId)) {
            throw new CatalogDomainException("SKU '{$dto->sku}' already exists.");
        }

        if ($dto->barcode && $this->repository->existsByBarcode($dto->barcode, $dto->businessId)) {
            throw new CatalogDomainException("Barcode '{$dto->barcode}' already exists.");
        }
        
        if ($dto->conversionFactor <= 0) {
            throw new CatalogDomainException("Conversion factor must be greater than 0.");
        }
        
        if ($dto->purchasePrice < 0 || $dto->minimumPrice < 0) {
            throw new CatalogDomainException("Prices cannot be negative.");
        }
        
        if ($dto->sellingPrice < $dto->minimumPrice) {
            throw new CatalogDomainException("Selling price cannot be less than minimum price.");
        }

        if ($dto->isBaseUnit) {
            $this->repository->unsetBaseUnit($dto->productId);
        } else {
            if (!$this->repository->hasBaseUnit($dto->productId)) {
                // If it's the first unit, force it to be the base unit
                $dto = new CreateProductUnitDTO(
                    businessId: $dto->businessId,
                    productId: $dto->productId,
                    unitId: $dto->unitId,
                    sku: $dto->sku,
                    barcode: $dto->barcode,
                    conversionFactor: $dto->conversionFactor,
                    purchasePrice: $dto->purchasePrice,
                    sellingPrice: $dto->sellingPrice,
                    minimumPrice: $dto->minimumPrice,
                    isBaseUnit: true
                );
            }
        }

        return $this->repository->create($dto->toArray());
    }
}
