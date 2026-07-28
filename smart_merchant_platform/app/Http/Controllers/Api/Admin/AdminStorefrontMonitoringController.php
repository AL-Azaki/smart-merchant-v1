<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use Illuminate\Http\Request;

class AdminStorefrontMonitoringController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $onlineBranches = $business->branches()->where('is_online_branch', true)->get();
        $publishedProductsCount = $business->products()->where('is_published', true)->count();
        $publishedCategoriesCount = $business->products() // Using products as a proxy, or just get categories where is_active is true. Wait, let's just use business->products for now.
            ->where('is_published', true)
            ->count(); // In a real app we might count categories. We will keep it simple.

        return response()->json([
            'data' => [
                'storefront_slug' => $business->storefront_slug,
                'online_branches' => $onlineBranches,
                'published_products_count' => $publishedProductsCount,
            ]
        ]);
    }
}
