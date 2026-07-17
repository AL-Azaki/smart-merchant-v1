<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\DTOs\CreateProductDTO;
use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Models\Brand;
use App\Domains\Finance\Models\Tax;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class CreateProductAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(CreateProductDTO $dto): Product
    {
        if ($this->repository->existsByCode($dto->productCode, $dto->businessId)) {
            throw new CatalogDomainException("Product code '{$dto->productCode}' already exists.");
        }

        if ($dto->categoryId) {
            $cat = Category::find($dto->categoryId);
            if (!$cat || $cat->business_id !== $dto->businessId) {
                throw new CatalogDomainException("Category does not exist or does not belong to this business.");
            }
        }

        if ($dto->brandId) {
            $brand = Brand::find($dto->brandId);
            if (!$brand || $brand->business_id !== $dto->businessId) {
                throw new CatalogDomainException("Brand does not exist or does not belong to this business.");
            }
        }

        if ($dto->taxId) {
            $tax = Tax::find($dto->taxId);
            if (!$tax || $tax->business_id !== $dto->businessId) {
                throw new CatalogDomainException("Tax does not exist or does not belong to this business.");
            }
        }

        return $this->repository->create($dto->toArray());
    }
}
