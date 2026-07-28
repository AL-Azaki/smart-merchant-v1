<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Storefront\StorefrontOrderRequest;
use App\Services\Storefront\StorefrontOrderService;
use App\Services\Storefront\StorefrontQueryService;
use Illuminate\Http\Request;

class StorefrontController extends Controller
{
    protected $queryService;
    protected $orderService;

    public function __construct(StorefrontQueryService $queryService, StorefrontOrderService $orderService)
    {
        $this->queryService = $queryService;
        $this->orderService = $orderService;
    }

    public function bootstrap($store)
    {
        return $this->queryService->getBootstrapData($store);
    }

    public function categories($store)
    {
        return $this->queryService->getCategories($store);
    }

    public function products(Request $request, $store)
    {
        return $this->queryService->getProducts($store, $request->all());
    }

    public function productDetail($store, $product)
    {
        return $this->queryService->getProductDetail($store, $product);
    }

    public function createOrder(StorefrontOrderRequest $request, $store)
    {
        return $this->orderService->createOrder($store, $request->validated());
    }
}
