<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Domains\Catalog\Resources\productUnitUnitResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Catalog\Models\productUnitUnit;

// Requests
use App\Domains\Catalog\Requests\StoreproductUnitUnitRequest;
use App\Domains\Catalog\Requests\ViewproductUnitUnitRequest;
use App\Domains\Catalog\Requests\ListproductUnitUnitsRequest;
use App\Domains\Catalog\Requests\SearchproductUnitUnitsRequest;
use App\Domains\Catalog\Requests\UpdateproductUnitUnitRequest;
use App\Domains\Catalog\Requests\DeleteproductUnitUnitRequest;
use App\Domains\Catalog\Requests\ActivateproductUnitUnitRequest;
use App\Domains\Catalog\Requests\DeactivateproductUnitUnitRequest;

// DTOs
use App\Domains\Catalog\DTOs\CreateproductUnitUnitDTO;
use App\Domains\Catalog\DTOs\ViewproductUnitUnitDTO;
use App\Domains\Catalog\DTOs\productUnitUnitListCriteriaDTO;
use App\Domains\Catalog\DTOs\productUnitUnitsearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateproductUnitUnitDTO;

// Actions
use App\Domains\Catalog\Actions\productUnitUnit\CreateproductUnitUnitAction;
use App\Domains\Catalog\Actions\productUnitUnit\ViewproductUnitUnitAction;
use App\Domains\Catalog\Actions\productUnitUnit\ListproductUnitUnitsAction;
use App\Domains\Catalog\Actions\productUnitUnit\SearchproductUnitUnitsAction;
use App\Domains\Catalog\Actions\productUnitUnit\UpdateproductUnitUnitAction;
use App\Domains\Catalog\Actions\productUnitUnit\DeleteproductUnitUnitAction;
use App\Domains\Catalog\Actions\productUnitUnit\ActivateproductUnitUnitAction;
use App\Domains\Catalog\Actions\productUnitUnit\DeactivateproductUnitUnitAction;

class ProductUnitController extends Controller
{
    use AuthorizesRequests;

    public function index(ListproductUnitUnitsRequest $request, ListproductUnitUnitsAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', productUnitUnit::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = productUnitUnitListCriteriaDTO::fromRequest($data);
        return productUnitUnitResource::collection($action->handle($criteria));
    }

    public function search(SearchproductUnitUnitsRequest $request, SearchproductUnitUnitsAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', productUnitUnit::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = productUnitUnitsearchCriteriaDTO::fromRequest($data);
        return productUnitUnitResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewproductUnitUnitRequest $request, ViewproductUnitUnitAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = ViewproductUnitUnitDTO::fromRequest($data, $id);
        $productUnitUnit = $action->handle($dto);
        $this->authorize('view', $productUnitUnit);
        return response()->json(new productUnitUnitResource($productUnitUnit));
    }

    public function store(StoreproductUnitUnitRequest $request, CreateproductUnitUnitAction $action): JsonResponse
    {
        $this->authorize('create', productUnitUnit::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = CreateproductUnitUnitDTO::fromRequest($data);
        $productUnitUnit = $action->handle($dto);
        return response()->json(new productUnitUnitResource($productUnitUnit), 201);
    }

    public function update(string $id, UpdateproductUnitUnitRequest $request, UpdateproductUnitUnitAction $action, ViewproductUnitUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewproductUnitUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $productUnitUnit = $viewAction->handle($viewDto);
        $this->authorize('update', $productUnitUnit);

        $dto = UpdateproductUnitUnitDTO::fromRequest($request->validated());
        $updatedproductUnitUnit = $action->handle($productUnitUnit, $dto);
        return response()->json(new productUnitUnitResource($updatedproductUnitUnit));
    }

    public function destroy(string $id, DeleteproductUnitUnitRequest $request, DeleteproductUnitUnitAction $action, ViewproductUnitUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewproductUnitUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $productUnitUnit = $viewAction->handle($viewDto);
        $this->authorize('delete', $productUnitUnit);

        $action->handle($productUnitUnit);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateproductUnitUnitRequest $request, ActivateproductUnitUnitAction $action, ViewproductUnitUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewproductUnitUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $productUnitUnit = $viewAction->handle($viewDto);
        $this->authorize('update', $productUnitUnit);

        $activatedproductUnitUnit = $action->handle($productUnitUnit);
        return response()->json(new productUnitUnitResource($activatedproductUnitUnit));
    }

    public function deactivate(string $id, DeactivateproductUnitUnitRequest $request, DeactivateproductUnitUnitAction $action, ViewproductUnitUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewproductUnitUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $productUnitUnit = $viewAction->handle($viewDto);
        $this->authorize('update', $productUnitUnit);

        $deactivatedproductUnitUnit = $action->handle($productUnitUnit);
        return response()->json(new productUnitUnitResource($deactivatedproductUnitUnit));
    }
}








