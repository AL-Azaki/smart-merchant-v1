<?php

namespace App\Http\Controllers\Api\V1\Inventory;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Http\Requests\Warehouse\StoreWarehouseRequest;
use App\Domains\Inventory\Http\Requests\Warehouse\UpdateWarehouseRequest;
use App\Domains\Inventory\Http\Resources\WarehouseResource;
use App\Domains\Inventory\DTOs\Warehouse\CreateWarehouseDTO;
use App\Domains\Inventory\DTOs\Warehouse\UpdateWarehouseDTO;
use App\Domains\Inventory\DTOs\Warehouse\WarehouseCriteriaDTO;
use App\Domains\Inventory\Actions\Warehouse\CreateWarehouseAction;
use App\Domains\Inventory\Actions\Warehouse\UpdateWarehouseAction;
use App\Domains\Inventory\Actions\Warehouse\DeleteWarehouseAction;
use App\Domains\Inventory\Actions\Warehouse\ActivateWarehouseAction;
use App\Domains\Inventory\Actions\Warehouse\DeactivateWarehouseAction;
use App\Domains\Inventory\Actions\Warehouse\GetWarehouseAction;
use App\Domains\Inventory\Actions\Warehouse\ListWarehousesAction;

class WarehouseController extends Controller
{
    public function index(Request $request, ListWarehousesAction $action): JsonResponse
    {
        $this->authorize('viewAny', Warehouse::class);

        $dto = WarehouseCriteriaDTO::fromRequest(array_merge($request->all(), [
            'business_id' => $request->user()->business_id
        ]));

        $paginator = $action->handle($dto);

        return response()->json([
            'data' => WarehouseResource::collection($paginator),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total()
            ]
        ]);
    }

    public function search(Request $request, ListWarehousesAction $action): JsonResponse
    {
        return $this->index($request, $action);
    }

    public function store(StoreWarehouseRequest $request, CreateWarehouseAction $action): JsonResponse
    {
        $this->authorize('create', Warehouse::class);

        $dto = CreateWarehouseDTO::fromRequest(array_merge($request->validated(), [
            'business_id' => $request->user()->business_id
        ]));

        $warehouse = $action->handle($dto);

        return response()->json(new WarehouseResource($warehouse), 201);
    }

    public function show(string $id, Request $request, GetWarehouseAction $action): JsonResponse
    {
        $warehouse = $action->handle($id, $request->user()->business_id);
        $this->authorize('view', $warehouse);

        return response()->json(new WarehouseResource($warehouse));
    }

    public function update(string $id, UpdateWarehouseRequest $request, UpdateWarehouseAction $action, GetWarehouseAction $getWarehouse): JsonResponse
    {
        $warehouse = $getWarehouse->handle($id, $request->user()->business_id);
        $this->authorize('update', $warehouse);

        $dto = UpdateWarehouseDTO::fromRequest($request->validated());
        $updatedWarehouse = $action->handle($warehouse, $dto);

        return response()->json(new WarehouseResource($updatedWarehouse));
    }

    public function destroy(string $id, Request $request, DeleteWarehouseAction $action, GetWarehouseAction $getWarehouse): JsonResponse
    {
        $warehouse = $getWarehouse->handle($id, $request->user()->business_id);
        $this->authorize('delete', $warehouse);

        $action->handle($warehouse);

        return response()->json(null, 204);
    }

    public function activate(string $id, Request $request, ActivateWarehouseAction $action, GetWarehouseAction $getWarehouse): JsonResponse
    {
        $warehouse = $getWarehouse->handle($id, $request->user()->business_id);
        $this->authorize('update', $warehouse);

        $activated = $action->handle($warehouse);

        return response()->json(new WarehouseResource($activated));
    }

    public function deactivate(string $id, Request $request, DeactivateWarehouseAction $action, GetWarehouseAction $getWarehouse): JsonResponse
    {
        $warehouse = $getWarehouse->handle($id, $request->user()->business_id);
        $this->authorize('update', $warehouse);

        $deactivated = $action->handle($warehouse);

        return response()->json(new WarehouseResource($deactivated));
    }
}
