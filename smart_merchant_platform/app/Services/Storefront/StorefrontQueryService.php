<?php

namespace App\Services\Storefront;

use App\Http\Resources\Storefront\CategoryResource;
use App\Http\Resources\Storefront\ProductDetailResource;
use App\Http\Resources\Storefront\ProductListResource;
use App\Http\Resources\Storefront\StorefrontBootstrapResource;
use App\Models\Business;
use App\Models\Category;
use App\Models\InventoryProjection;
use App\Models\Product;

class StorefrontQueryService
{
    protected function getBusinessBySlug($slug)
    {
        $business = Business::where('storefront_slug', $slug)
            ->where('status', 'Active')
            ->first();

        if (! $business || ! $business->storefront_active) {
            abort(404, 'Storefront not found or not active');
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

        $query = Category::forBusiness($business->id)
            ->where('is_active', true)
            ->orderBy('category_name');

        if (request()->boolean('only_with_products') || request()->boolean('has_products')) {
            $query->whereHas('products', function ($q) use ($business) {
                $q->publishedToStorefront($business->id);
            });
        }

        return CategoryResource::collection($query->get());
    }

    public function getProducts($slug, array $filters)
    {
        $business = $this->getBusinessBySlug($slug);
        $branchId = $filters['branch_id'] ?? null;

        $query = Product::publishedToStorefront($business->id)
            ->with([
                'category',
                'brand',
                'images' => function ($q) {
                    $q->orderBy('is_primary', 'desc');
                },
                'units' => function ($q) use ($branchId) {
                    $q->where('is_active', true)->with('unit');
                    if ($branchId) {
                        $q->leftJoin('inventory_projections', function ($join) use ($branchId) {
                            $join->on('inventory_projections.product_unit_id', '=', 'product_units.id')
                                ->where('inventory_projections.branch_id', '=', $branchId);
                        })->select('product_units.*', 'inventory_projections.quantity as inventory_quantity');
                    }
                },
            ]);

        if (isset($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }

        if (! empty($filters['search'])) {
            $search = strtolower($filters['search']);
            $query->whereRaw('LOWER(product_name) LIKE ?', ['%'.$search.'%']);
        }

        $products = $query->paginate($filters['per_page'] ?? 15);

        return ProductListResource::collection($products);
    }

    public function getProductDetail($slug, $productId)
    {
        $business = $this->getBusinessBySlug($slug);

        $product = Product::publishedToStorefront($business->id)
            ->with([
                'category',
                'brand',
                'images' => function ($q) {
                    $q->orderBy('is_primary', 'desc');
                },
                'units' => function ($q) {
                    $q->where('is_active', true)->with('unit');
                },
            ])
            ->findOrFail($productId);

        $branchId = request('branch_id');
        if ($branchId) {
            $product->units->each(function ($unit) use ($branchId) {
                $proj = InventoryProjection::where('product_unit_id', $unit->id)
                    ->where('branch_id', $branchId)
                    ->first();
                $unit->inventory_quantity = $proj ? $proj->quantity : 0;
            });
        }

        return new ProductDetailResource($product);
    }
}
