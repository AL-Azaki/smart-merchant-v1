<?php

namespace App\Services\Storefront;

use App\Http\Resources\Storefront\ProductListResource;
use App\Models\Business;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImage;
use Illuminate\Http\Request;

class MarketplaceQueryService
{
    /**
     * Get aggregate explore data for central marketplace homepage.
     */
    public function getExploreData(Request $request): array
    {
        $search = trim($request->input('q', ''));
        $categoryId = $request->input('category_id');

        // 1. Active & verified merchants
        $merchantsQuery = Business::where('status', 'Active')
            ->where('storefront_active', true)
            ->whereNotNull('storefront_slug')
            ->withCount([
                'products as active_products_count' => function ($q) {
                    $q->where('show_in_store', true)
                      ->where('is_active', true)
                      ->whereNull('deleted_at');
                },
            ]);

        if (! empty($search)) {
            $merchantsQuery->where(function ($q) use ($search) {
                $q->where('business_name', 'ilike', "%{$search}%")
                  ->orWhere('storefront_display_name', 'ilike', "%{$search}%")
                  ->orWhere('storefront_slug', 'ilike', "%{$search}%");
            });
        }

        $merchants = $merchantsQuery->orderByDesc('active_products_count')
            ->limit(12)
            ->get()
            ->map(function ($business) {
                return [
                    'id' => $business->id,
                    'name' => $business->storefront_display_name ?: $business->business_name,
                    'slug' => $business->storefront_slug,
                    'logo' => ProductImage::sanitizePublicImageUrl($business->logo_path),
                    'business_type' => $business->business_type,
                    'address' => $business->storefront_address_text,
                    'phone' => $business->storefront_phone ?: $business->primary_phone,
                    'whatsapp' => $business->storefront_whatsapp,
                    'active_products_count' => (int) $business->active_products_count,
                    'theme_settings' => $business->storefront_theme_settings,
                ];
            });

        // 2. Active products across all active merchants
        $productsQuery = Product::where('show_in_store', true)
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->whereHas('business', function ($q) {
                $q->where('status', 'Active')
                  ->where('storefront_active', true)
                  ->whereNotNull('storefront_slug');
            })
            ->with([
                'business:id,business_name,storefront_display_name,storefront_slug,logo_path',
                'category:id,category_name',
                'images' => function ($q) {
                    $q->orderByDesc('is_primary');
                },
                'units' => function ($q) {
                    $q->where('is_active', true)->orderBy('selling_price');
                },
            ]);

        if (! empty($search)) {
            $productsQuery->where(function ($q) use ($search) {
                $q->where('product_name', 'ilike', "%{$search}%")
                  ->orWhere('product_code', 'ilike', "%{$search}%")
                  ->orWhere('description', 'ilike', "%{$search}%")
                  ->orWhereHas('business', function ($bq) use ($search) {
                      $bq->where('business_name', 'ilike', "%{$search}%")
                         ->orWhere('storefront_display_name', 'ilike', "%{$search}%");
                  });
            });
        }

        if (! empty($categoryId)) {
            $productsQuery->where('category_id', $categoryId);
        }

        $products = $productsQuery->latest()
            ->limit(24)
            ->get()
            ->map(function ($product) {
                $resource = (new ProductListResource($product))->toArray(request());
                $resource['merchant'] = [
                    'id' => $product->business?->id,
                    'name' => $product->business?->storefront_display_name ?: $product->business?->business_name,
                    'slug' => $product->business?->storefront_slug,
                    'logo' => ProductImage::sanitizePublicImageUrl($product->business?->logo_path),
                ];

                return $resource;
            });

        // 3. Popular categories with available products
        $categories = Category::where('is_active', true)
            ->whereHas('products', function ($q) {
                $q->where('show_in_store', true)
                  ->where('is_active', true)
                  ->whereNull('deleted_at')
                  ->whereHas('business', function ($bq) {
                      $bq->where('status', 'Active')
                         ->where('storefront_active', true);
                  });
            })
            ->withCount([
                'products as live_products_count' => function ($q) {
                    $q->where('show_in_store', true)
                      ->where('is_active', true)
                      ->whereNull('deleted_at')
                      ->whereHas('business', function ($bq) {
                          $bq->where('status', 'Active')
                             ->where('storefront_active', true);
                      });
                },
            ])
            ->orderByDesc('live_products_count')
            ->limit(10)
            ->get()
            ->map(function ($cat) {
                return [
                    'id' => $cat->id,
                    'name' => $cat->category_name,
                    'products_count' => (int) $cat->live_products_count,
                ];
            });

        // 4. Marketing Hero Banners & Stories Prompts
        $marketingBanners = [
            [
                'id' => 'hero-1',
                'title' => 'تسوق من متاجرك المفضلة محلياً بدون وسيط',
                'subtitle' => 'اكتشف أفضل المنتجات من التجار المعتمدين في مدينتك بعمولة 0% مع توصيل مباشر وسريع لباب بيتك.',
                'badge' => 'منصة تاجركم (Tajer) الرسمية',
                'cta_text' => 'استكشف المتاجر',
                'cta_link' => '#merchants-section',
                'gradient' => 'from-blue-600 via-indigo-600 to-purple-700',
            ],
            [
                'id' => 'hero-2',
                'title' => 'هل أنت تاجر؟ انطلق بمتجرك الرقمي اليوم!',
                'subtitle' => 'اربط كاشيرك ومخازنك بمتجر إلكتروني احترافي يستقبل الطلبات على مدار الساعة مع مزامنة لحظية.',
                'badge' => 'بوابة تجار تاجركم (Tajer)',
                'cta_text' => 'افتح متجرك الآن',
                'cta_link' => '/merchants/onboarding',
                'gradient' => 'from-emerald-600 via-teal-600 to-cyan-700',
            ],
        ];

        return [
            'status' => 'success',
            'data' => [
                'merchants' => $merchants,
                'products' => $products,
                'categories' => $categories,
                'banners' => $marketingBanners,
                'total_merchants' => $merchants->count(),
                'total_products' => $products->count(),
            ],
        ];
    }
}
