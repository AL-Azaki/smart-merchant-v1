<?php

namespace App\Domains\Catalog\Actions\ProductUnit;

use App\Domains\Catalog\DTOs\UpdateProductUnitDTO;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Catalog\Repositories\Contracts\ProductUnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class UpdateProductUnitAction
{
    public function __construct(private readonly ProductUnitRepositoryInterface $repository) {}

    public function handle(ProductUnit $productUnit, UpdateProductUnitDTO $dto): ProductUnit
    {
        if ($dto->sku !== null && $dto->sku !== $productUnit->sku) {
            if ($this->repository->existsBySku($dto->sku, $productUnit->business_id)) {
                throw new CatalogDomainException("SKU '{$dto->sku}' already exists.");
            }
        }

        if ($dto->barcode !== null && $dto->barcode !== $productUnit->barcode) {
            if ($this->repository->existsByBarcode($dto->barcode, $productUnit->business_id)) {
                throw new CatalogDomainException("Barcode '{$dto->barcode}' already exists.");
            }
        }
        
        $conversion = $dto->conversionFactor ?? $productUnit->conversion_factor;
        $purchase = $dto->purchasePrice ?? $productUnit->purchase_price;
        $selling = $dto->sellingPrice ?? $productUnit->selling_price;
        $min = $dto->minimumPrice ?? $productUnit->minimum_price;
        
        if ($conversion <= 0) {
            throw new CatalogDomainException("Conversion factor must be greater than 0.");
        }
        if ($purchase < 0 || $min < 0) {
            throw new CatalogDomainException("Prices cannot be negative.");
        }
        if ($selling < $min) {
            throw new CatalogDomainException("Selling price cannot be less than minimum price.");
        }

        if ($dto->isBaseUnit === true && !$productUnit->is_base_unit) {
            $this->repository->unsetBaseUnit($productUnit->product_id);
        }
        
        if ($dto->isBaseUnit === false && $productUnit->is_base_unit) {
            throw new CatalogDomainException("Cannot unset the base unit. You must set another unit as the base unit instead.");
        }

        return $this->repository->update($productUnit, $dto);
    }
}
