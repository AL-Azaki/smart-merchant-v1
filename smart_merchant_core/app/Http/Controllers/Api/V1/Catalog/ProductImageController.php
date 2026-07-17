<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Domains\Catalog\Resources\productImageImageResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Catalog\Models\productImageImage;

// Requests
use App\Domains\Catalog\Requests\StoreproductImageImageRequest;
use App\Domains\Catalog\Requests\ViewproductImageImageRequest;
use App\Domains\Catalog\Requests\ListproductImageImagesRequest;
use App\Domains\Catalog\Requests\SearchproductImageImagesRequest;
use App\Domains\Catalog\Requests\UpdateproductImageImageRequest;
use App\Domains\Catalog\Requests\DeleteproductImageImageRequest;
use App\Domains\Catalog\Requests\ActivateproductImageImageRequest;
use App\Domains\Catalog\Requests\DeactivateproductImageImageRequest;

// DTOs
use App\Domains\Catalog\DTOs\CreateproductImageImageDTO;
use App\Domains\Catalog\DTOs\ViewproductImageImageDTO;
use App\Domains\Catalog\DTOs\productImageImageListCriteriaDTO;
use App\Domains\Catalog\DTOs\productImageImagesearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateproductImageImageDTO;

// Actions
use App\Domains\Catalog\Actions\productImageImage\CreateproductImageImageAction;
use App\Domains\Catalog\Actions\productImageImage\ViewproductImageImageAction;
use App\Domains\Catalog\Actions\productImageImage\ListproductImageImagesAction;
use App\Domains\Catalog\Actions\productImageImage\SearchproductImageImagesAction;
use App\Domains\Catalog\Actions\productImageImage\UpdateproductImageImageAction;
use App\Domains\Catalog\Actions\productImageImage\DeleteproductImageImageAction;
use App\Domains\Catalog\Actions\productImageImage\ActivateproductImageImageAction;
use App\Domains\Catalog\Actions\productImageImage\DeactivateproductImageImageAction;

class ProductImageController extends Controller
{
    use AuthorizesRequests;

    public function index(ListproductImageImagesRequest $request, ListproductImageImagesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', productImageImage::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = productImageImageListCriteriaDTO::fromRequest($data);
        return productImageImageResource::collection($action->handle($criteria));
    }

    public function search(SearchproductImageImagesRequest $request, SearchproductImageImagesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', productImageImage::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = productImageImagesearchCriteriaDTO::fromRequest($data);
        return productImageImageResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewproductImageImageRequest $request, ViewproductImageImageAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = ViewproductImageImageDTO::fromRequest($data, $id);
        $productImageImage = $action->handle($dto);
        $this->authorize('view', $productImageImage);
        return response()->json(new productImageImageResource($productImageImage));
    }

    public function store(StoreproductImageImageRequest $request, CreateproductImageImageAction $action): JsonResponse
    {
        $this->authorize('create', productImageImage::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = CreateproductImageImageDTO::fromRequest($data);
        $productImageImage = $action->handle($dto);
        return response()->json(new productImageImageResource($productImageImage), 201);
    }

    public function update(string $id, UpdateproductImageImageRequest $request, UpdateproductImageImageAction $action, ViewproductImageImageAction $viewAction): JsonResponse
    {
        $viewDto = ViewproductImageImageDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $productImageImage = $viewAction->handle($viewDto);
        $this->authorize('update', $productImageImage);

        $dto = UpdateproductImageImageDTO::fromRequest($request->validated());
        $updatedproductImageImage = $action->handle($productImageImage, $dto);
        return response()->json(new productImageImageResource($updatedproductImageImage));
    }

    public function destroy(string $id, DeleteproductImageImageRequest $request, DeleteproductImageImageAction $action, ViewproductImageImageAction $viewAction): JsonResponse
    {
        $viewDto = ViewproductImageImageDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $productImageImage = $viewAction->handle($viewDto);
        $this->authorize('delete', $productImageImage);

        $action->handle($productImageImage);
        return response()->json(null, 204);
    }

    
}








