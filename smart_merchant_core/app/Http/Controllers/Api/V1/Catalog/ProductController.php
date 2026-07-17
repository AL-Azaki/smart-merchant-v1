<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Domains\Catalog\Resources\ProductResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Catalog\Models\Product;

// Requests
use App\Domains\Catalog\Requests\StoreProductRequest;
use App\Domains\Catalog\Requests\ViewProductRequest;
use App\Domains\Catalog\Requests\ListProductsRequest;
use App\Domains\Catalog\Requests\SearchProductsRequest;
use App\Domains\Catalog\Requests\UpdateProductRequest;
use App\Domains\Catalog\Requests\DeleteProductRequest;
use App\Domains\Catalog\Requests\ActivateProductRequest;
use App\Domains\Catalog\Requests\DeactivateProductRequest;

// DTOs
use App\Domains\Catalog\DTOs\CreateProductDTO;
use App\Domains\Catalog\DTOs\ViewProductDTO;
use App\Domains\Catalog\DTOs\ProductListCriteriaDTO;
use App\Domains\Catalog\DTOs\ProductsearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateProductDTO;

// Actions
use App\Domains\Catalog\Actions\Product\CreateProductAction;
use App\Domains\Catalog\Actions\Product\ViewProductAction;
use App\Domains\Catalog\Actions\Product\ListProductsAction;
use App\Domains\Catalog\Actions\Product\SearchProductsAction;
use App\Domains\Catalog\Actions\Product\UpdateProductAction;
use App\Domains\Catalog\Actions\Product\DeleteProductAction;
use App\Domains\Catalog\Actions\Product\ActivateProductAction;
use App\Domains\Catalog\Actions\Product\DeactivateProductAction;

class ProductController extends Controller
{
    use AuthorizesRequests;

    public function index(ListProductsRequest $request, ListProductsAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Product::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = ProductListCriteriaDTO::fromRequest($data);
        return ProductResource::collection($action->handle($criteria));
    }

    public function search(SearchProductsRequest $request, SearchProductsAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Product::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = ProductsearchCriteriaDTO::fromRequest($data);
        return ProductResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewProductRequest $request, ViewProductAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = ViewProductDTO::fromRequest($data, $id);
        $Product = $action->handle($dto);
        $this->authorize('view', $Product);
        return response()->json(new ProductResource($Product));
    }

    public function store(StoreProductRequest $request, CreateProductAction $action): JsonResponse
    {
        $this->authorize('create', Product::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = CreateProductDTO::fromRequest($data);
        $Product = $action->handle($dto);
        return response()->json(new ProductResource($Product), 201);
    }

    public function update(string $id, UpdateProductRequest $request, UpdateProductAction $action, ViewProductAction $viewAction): JsonResponse
    {
        $viewDto = ViewProductDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $Product = $viewAction->handle($viewDto);
        $this->authorize('update', $Product);

        $dto = UpdateProductDTO::fromRequest($request->validated());
        $updatedProduct = $action->handle($Product, $dto);
        return response()->json(new ProductResource($updatedProduct));
    }

    public function destroy(string $id, DeleteProductRequest $request, DeleteProductAction $action, ViewProductAction $viewAction): JsonResponse
    {
        $viewDto = ViewProductDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $Product = $viewAction->handle($viewDto);
        $this->authorize('delete', $Product);

        $action->handle($Product);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateProductRequest $request, ActivateProductAction $action, ViewProductAction $viewAction): JsonResponse
    {
        $viewDto = ViewProductDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $Product = $viewAction->handle($viewDto);
        $this->authorize('update', $Product);

        $activatedProduct = $action->handle($Product);
        return response()->json(new ProductResource($activatedProduct));
    }

    public function deactivate(string $id, DeactivateProductRequest $request, DeactivateProductAction $action, ViewProductAction $viewAction): JsonResponse
    {
        $viewDto = ViewProductDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $Product = $viewAction->handle($viewDto);
        $this->authorize('update', $Product);

        $deactivatedProduct = $action->handle($Product);
        return response()->json(new ProductResource($deactivatedProduct));
    }
}







