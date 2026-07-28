<?php

namespace App\Services\Storefront;

use App\Models\Business;
use App\Models\Category;
use App\Models\Product;
use App\Http\Resources\Storefront\StorefrontBootstrapResource;
use App\Http\Resources\Storefront\CategoryResource;
use App\Http\Resources\Storefront\ProductListResource;
use App\Http\Resources\Storefront\ProductDetailResource;

class StorefrontQueryService
{
    protected function getBusinessBySlug($slug)
    {
        $business = Business::where('storefront_slug', $slug)
            ->where('status', 'Active')
            ->first();

        if (!$business) {
            abort(404, 'Storefront not found');
        }

        return $business;
    }

    public function getBootstrapData($slug)
    {
        $business = $this->getBusinessBySlug($slug);
        return new StorefrontBootstrapResource($business);
    }

    public function getCategories($slug)
    {
        $business = $this->getBusinessBySlug($slug);

        $categories = Category::forBusiness($business->id)
            ->where('is_active', true)
            ->orderBy('category_name')
            ->get();

        return CategoryResource::collection($categories);
    }

    public function getProducts($slug, array $filters)
    {
        $business = $this->getBusinessBySlug($slug);
        $branchId = $filters['branch_id'] ?? null;

        $query = Product::forBusiness($business->id)
            ->where('is_active', true)
            ->with(['images' => function($q) {
                $q->orderBy('is_primary', 'desc');
            }]);

        if (isset($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }

        if (isset($filters['search'])) {
            $query->where('product_name', 'ilike', '%' . $filters['search'] . '%');
        }
        
        $query->with(['units' => function($q) use ($branchId) {
            if ($branchId) {
                $q->leftJoin('inventory_projections', function($join) use ($branchId) {
                    $join->on('inventory_projections.product_unit_id', '=', 'product_units.id')
                         ->where('inventory_projections.branch_id', '=', $branchId);
                })->select('product_units.*', 'inventory_projections.quantity as inventory_quantity');
            }
        }]);

        $products = $query->paginate($filters['per_page'] ?? 15);

        return ProductListResource::collection($products);
    }

    public function getProductDetail($slug, $productId)
    {
        $business = $this->getBusinessBySlug($slug);

        $product = Product::forBusiness($business->id)
            ->where('is_active', true)
            ->with(['category', 'images' => function($q) {
                $q->orderBy('is_primary', 'desc');
            }, 'units'])
            ->findOrFail($productId);

        $branchId = request('branch_id');
        if ($branchId) {
            $product->units->each(function($unit) use ($branchId) {
                $proj = \App\Models\InventoryProjection::where('product_unit_id', $unit->id)
                    ->where('branch_id', $branchId)
                    ->first();
                $unit->inventory_quantity = $proj ? $proj->quantity : 0;
            });
        }

        return new ProductDetailResource($product);
    }
}
