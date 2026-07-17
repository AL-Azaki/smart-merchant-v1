<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Domains\Catalog\Resources\UnitResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Catalog\Models\Unit;

// Requests
use App\Domains\Catalog\Requests\StoreUnitRequest;
use App\Domains\Catalog\Requests\ViewUnitRequest;
use App\Domains\Catalog\Requests\ListUnitsRequest;
use App\Domains\Catalog\Requests\SearchUnitsRequest;
use App\Domains\Catalog\Requests\UpdateUnitRequest;
use App\Domains\Catalog\Requests\DeleteUnitRequest;
use App\Domains\Catalog\Requests\ActivateUnitRequest;
use App\Domains\Catalog\Requests\DeactivateUnitRequest;

// DTOs
use App\Domains\Catalog\DTOs\CreateUnitDTO;
use App\Domains\Catalog\DTOs\ViewUnitDTO;
use App\Domains\Catalog\DTOs\UnitListCriteriaDTO;
use App\Domains\Catalog\DTOs\UnitSearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateUnitDTO;

// Actions
use App\Domains\Catalog\Actions\Unit\CreateUnitAction;
use App\Domains\Catalog\Actions\Unit\ViewUnitAction;
use App\Domains\Catalog\Actions\Unit\ListUnitsAction;
use App\Domains\Catalog\Actions\Unit\SearchUnitsAction;
use App\Domains\Catalog\Actions\Unit\UpdateUnitAction;
use App\Domains\Catalog\Actions\Unit\DeleteUnitAction;
use App\Domains\Catalog\Actions\Unit\ActivateUnitAction;
use App\Domains\Catalog\Actions\Unit\DeactivateUnitAction;

class UnitController extends Controller
{
    use AuthorizesRequests;

    public function index(ListUnitsRequest $request, ListUnitsAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Unit::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = UnitListCriteriaDTO::fromRequest($data);
        return UnitResource::collection($action->handle($criteria));
    }

    public function search(SearchUnitsRequest $request, SearchUnitsAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Unit::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = UnitSearchCriteriaDTO::fromRequest($data);
        return UnitResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewUnitRequest $request, ViewUnitAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = ViewUnitDTO::fromRequest($data, $id);
        $unit = $action->handle($dto);
        $this->authorize('view', $unit);
        return response()->json(new UnitResource($unit));
    }

    public function store(StoreUnitRequest $request, CreateUnitAction $action): JsonResponse
    {
        $this->authorize('create', Unit::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = CreateUnitDTO::fromRequest($data);
        $unit = $action->handle($dto);
        return response()->json(new UnitResource($unit), 201);
    }

    public function update(string $id, UpdateUnitRequest $request, UpdateUnitAction $action, ViewUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $unit = $viewAction->handle($viewDto);
        $this->authorize('update', $unit);

        $dto = UpdateUnitDTO::fromRequest($request->validated());
        $updatedUnit = $action->handle($unit, $dto);
        return response()->json(new UnitResource($updatedUnit));
    }

    public function destroy(string $id, DeleteUnitRequest $request, DeleteUnitAction $action, ViewUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $unit = $viewAction->handle($viewDto);
        $this->authorize('delete', $unit);

        $action->handle($unit);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateUnitRequest $request, ActivateUnitAction $action, ViewUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $unit = $viewAction->handle($viewDto);
        $this->authorize('update', $unit);

        $activatedUnit = $action->handle($unit);
        return response()->json(new UnitResource($activatedUnit));
    }

    public function deactivate(string $id, DeactivateUnitRequest $request, DeactivateUnitAction $action, ViewUnitAction $viewAction): JsonResponse
    {
        $viewDto = ViewUnitDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $unit = $viewAction->handle($viewDto);
        $this->authorize('update', $unit);

        $deactivatedUnit = $action->handle($unit);
        return response()->json(new UnitResource($deactivatedUnit));
    }
}



