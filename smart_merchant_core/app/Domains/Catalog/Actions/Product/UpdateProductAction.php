<?php

namespace App\Domains\Catalog\Actions\Product;

use App\Domains\Catalog\DTOs\UpdateProductDTO;
use App\Domains\Catalog\Models\Product;
use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\Models\Brand;
use App\Domains\Finance\Models\Tax;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class UpdateProductAction
{
    public function __construct(private readonly ProductRepositoryInterface $repository) {}

    public function handle(Product $product, UpdateProductDTO $dto): Product
    {
        if ($dto->productCode !== null && $dto->productCode !== $product->product_code) {
            if ($this->repository->existsByCode($dto->productCode, $product->business_id)) {
                throw new CatalogDomainException("Product code '{$dto->productCode}' already exists.");
            }
        }

        if ($dto->categoryId !== null) {
            $cat = Category::find($dto->categoryId);
            if (!$cat || $cat->business_id !== $product->business_id) {
                throw new CatalogDomainException("Category does not exist or does not belong to this business.");
            }
        }

        if ($dto->brandId !== null) {
            $brand = Brand::find($dto->brandId);
            if (!$brand || $brand->business_id !== $product->business_id) {
                throw new CatalogDomainException("Brand does not exist or does not belong to this business.");
            }
        }

        if ($dto->taxId !== null) {
            $tax = Tax::find($dto->taxId);
            if (!$tax || $tax->business_id !== $product->business_id) {
                throw new CatalogDomainException("Tax does not exist or does not belong to this business.");
            }
        }

        return $this->repository->update($product, $dto);
    }
}
