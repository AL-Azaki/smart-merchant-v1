<?php

namespace App\Http\Controllers\Api\V1\Inventory;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Http\Requests\Inventory\StoreInventoryRequest;
use App\Domains\Inventory\Http\Requests\Inventory\UpdateInventoryRequest;
use App\Domains\Inventory\Http\Resources\InventoryResource;
use App\Domains\Inventory\DTOs\Inventory\CreateInventoryDTO;
use App\Domains\Inventory\DTOs\Inventory\UpdateInventoryDTO;
use App\Domains\Inventory\DTOs\Inventory\InventoryCriteriaDTO;
use App\Domains\Inventory\Actions\Inventory\CreateInventoryAction;
use App\Domains\Inventory\Actions\Inventory\UpdateInventoryAction;
use App\Domains\Inventory\Actions\Inventory\DeleteInventoryAction;
use App\Domains\Inventory\Actions\Inventory\GetInventoryAction;
use App\Domains\Inventory\Actions\Inventory\ListInventoryAction;

class InventoryController extends Controller
{
    public function index(Request $request, ListInventoryAction $action): JsonResponse
    {
        $this->authorize('viewAny', Inventory::class);

        $dto = InventoryCriteriaDTO::fromRequest(array_merge($request->all(), [
            'business_id' => $request->user()->business_id
        ]));

        $paginator = $action->handle($dto);

        return response()->json([
            'data' => InventoryResource::collection($paginator),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total()
            ]
        ]);
    }

    public function search(Request $request, ListInventoryAction $action): JsonResponse
    {
        return $this->index($request, $action);
    }

    public function store(StoreInventoryRequest $request, CreateInventoryAction $action): JsonResponse
    {
        $this->authorize('create', Inventory::class);

        $dto = CreateInventoryDTO::fromRequest(array_merge($request->validated(), [
            'business_id' => $request->user()->business_id,
            'quantity' => 0,
            'average_cost' => 0
        ]));

        $inventory = $action->handle($dto);

        return response()->json(new InventoryResource($inventory), 201);
    }

    public function show(string $id, Request $request, GetInventoryAction $action): JsonResponse
    {
        $inventory = $action->handle($id, $request->user()->business_id);
        $this->authorize('view', $inventory);

        return response()->json(new InventoryResource($inventory));
    }

    public function update(string $id, UpdateInventoryRequest $request, UpdateInventoryAction $action, GetInventoryAction $getInventory): JsonResponse
    {
        $inventory = $getInventory->handle($id, $request->user()->business_id);
        $this->authorize('update', $inventory);

        $dto = UpdateInventoryDTO::fromRequest($request->validated());
        $updatedInventory = $action->handle($inventory, $dto);

        return response()->json(new InventoryResource($updatedInventory));
    }

    public function destroy(string $id, Request $request, DeleteInventoryAction $action, GetInventoryAction $getInventory): JsonResponse
    {
        $inventory = $getInventory->handle($id, $request->user()->business_id);
        $this->authorize('delete', $inventory);

        $action->handle($inventory);

        return response()->json(null, 204);
    }
}
