<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Domains\Catalog\Resources\BranchbranchProductPricePriceResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Catalog\Models\BranchbranchProductPricePrice;

// Requests
use App\Domains\Catalog\Requests\StoreBranchbranchProductPricePriceRequest;
use App\Domains\Catalog\Requests\ViewBranchbranchProductPricePriceRequest;
use App\Domains\Catalog\Requests\ListBranchbranchProductPricePricesRequest;
use App\Domains\Catalog\Requests\SearchBranchbranchProductPricePricesRequest;
use App\Domains\Catalog\Requests\UpdateBranchbranchProductPricePriceRequest;
use App\Domains\Catalog\Requests\DeleteBranchbranchProductPricePriceRequest;
use App\Domains\Catalog\Requests\ActivateBranchbranchProductPricePriceRequest;
use App\Domains\Catalog\Requests\DeactivateBranchbranchProductPricePriceRequest;

// DTOs
use App\Domains\Catalog\DTOs\CreateBranchbranchProductPricePriceDTO;
use App\Domains\Catalog\DTOs\ViewBranchbranchProductPricePriceDTO;
use App\Domains\Catalog\DTOs\BranchbranchProductPricePriceListCriteriaDTO;
use App\Domains\Catalog\DTOs\BranchbranchProductPricePricesearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateBranchbranchProductPricePriceDTO;

// Actions
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\CreateBranchbranchProductPricePriceAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\ViewBranchbranchProductPricePriceAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\ListBranchbranchProductPricePricesAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\SearchBranchbranchProductPricePricesAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\UpdateBranchbranchProductPricePriceAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\DeleteBranchbranchProductPricePriceAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\ActivateBranchbranchProductPricePriceAction;
use App\Domains\Catalog\Actions\BranchbranchProductPricePrice\DeactivateBranchbranchProductPricePriceAction;

class BranchProductPriceController extends Controller
{
    use AuthorizesRequests;

    public function index(ListBranchbranchProductPricePricesRequest $request, ListBranchbranchProductPricePricesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', BranchbranchProductPricePrice::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = BranchbranchProductPricePriceListCriteriaDTO::fromRequest($data);
        return BranchbranchProductPricePriceResource::collection($action->handle($criteria));
    }

    public function search(SearchBranchbranchProductPricePricesRequest $request, SearchBranchbranchProductPricePricesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', BranchbranchProductPricePrice::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = BranchbranchProductPricePricesearchCriteriaDTO::fromRequest($data);
        return BranchbranchProductPricePriceResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewBranchbranchProductPricePriceRequest $request, ViewBranchbranchProductPricePriceAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = ViewBranchbranchProductPricePriceDTO::fromRequest($data, $id);
        $BranchbranchProductPricePrice = $action->handle($dto);
        $this->authorize('view', $BranchbranchProductPricePrice);
        return response()->json(new BranchbranchProductPricePriceResource($BranchbranchProductPricePrice));
    }

    public function store(StoreBranchbranchProductPricePriceRequest $request, CreateBranchbranchProductPricePriceAction $action): JsonResponse
    {
        $this->authorize('create', BranchbranchProductPricePrice::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = CreateBranchbranchProductPricePriceDTO::fromRequest($data);
        $BranchbranchProductPricePrice = $action->handle($dto);
        return response()->json(new BranchbranchProductPricePriceResource($BranchbranchProductPricePrice), 201);
    }

    public function update(string $id, UpdateBranchbranchProductPricePriceRequest $request, UpdateBranchbranchProductPricePriceAction $action, ViewBranchbranchProductPricePriceAction $viewAction): JsonResponse
    {
        $viewDto = ViewBranchbranchProductPricePriceDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $BranchbranchProductPricePrice = $viewAction->handle($viewDto);
        $this->authorize('update', $BranchbranchProductPricePrice);

        $dto = UpdateBranchbranchProductPricePriceDTO::fromRequest($request->validated());
        $updatedBranchbranchProductPricePrice = $action->handle($BranchbranchProductPricePrice, $dto);
        return response()->json(new BranchbranchProductPricePriceResource($updatedBranchbranchProductPricePrice));
    }

    public function destroy(string $id, DeleteBranchbranchProductPricePriceRequest $request, DeleteBranchbranchProductPricePriceAction $action, ViewBranchbranchProductPricePriceAction $viewAction): JsonResponse
    {
        $viewDto = ViewBranchbranchProductPricePriceDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $BranchbranchProductPricePrice = $viewAction->handle($viewDto);
        $this->authorize('delete', $BranchbranchProductPricePrice);

        $action->handle($BranchbranchProductPricePrice);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateBranchbranchProductPricePriceRequest $request, ActivateBranchbranchProductPricePriceAction $action, ViewBranchbranchProductPricePriceAction $viewAction): JsonResponse
    {
        $viewDto = ViewBranchbranchProductPricePriceDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $BranchbranchProductPricePrice = $viewAction->handle($viewDto);
        $this->authorize('update', $BranchbranchProductPricePrice);

        $activatedBranchbranchProductPricePrice = $action->handle($BranchbranchProductPricePrice);
        return response()->json(new BranchbranchProductPricePriceResource($activatedBranchbranchProductPricePrice));
    }

    public function deactivate(string $id, DeactivateBranchbranchProductPricePriceRequest $request, DeactivateBranchbranchProductPricePriceAction $action, ViewBranchbranchProductPricePriceAction $viewAction): JsonResponse
    {
        $viewDto = ViewBranchbranchProductPricePriceDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $BranchbranchProductPricePrice = $viewAction->handle($viewDto);
        $this->authorize('update', $BranchbranchProductPricePrice);

        $deactivatedBranchbranchProductPricePrice = $action->handle($BranchbranchProductPricePrice);
        return response()->json(new BranchbranchProductPricePriceResource($deactivatedBranchbranchProductPricePrice));
    }
}








