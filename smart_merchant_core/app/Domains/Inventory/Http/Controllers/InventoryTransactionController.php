<?php

namespace App\Domains\Inventory\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Inventory\Http\Requests\InventoryTransaction\CreateInventoryTransactionRequest;
use App\Domains\Inventory\Http\Requests\InventoryTransaction\UpdateInventoryTransactionRequest;
use App\Domains\Inventory\Actions\InventoryTransaction\CreateInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\UpdateInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\DeleteInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\GetInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\ListInventoryTransactionsAction;
use App\Domains\Inventory\Http\Resources\InventoryTransactionResource;
use App\Domains\Inventory\Http\Resources\InventoryTransactionCollection;
use App\Domains\Inventory\Models\InventoryTransaction;

class InventoryTransactionController extends Controller
{
    use AuthorizesRequests;

    public function __construct(
        private CreateInventoryTransactionAction $createAction,
        private UpdateInventoryTransactionAction $updateAction,
        private DeleteInventoryTransactionAction $deleteAction,
        private GetInventoryTransactionAction $getAction,
        private ListInventoryTransactionsAction $listAction
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', InventoryTransaction::class);
        
        $transactions = $this->listAction->execute($request->user()->business_id);
        
        return response()->json(new InventoryTransactionCollection($transactions));
    }

    public function store(CreateInventoryTransactionRequest $request): JsonResponse
    {
        $this->authorize('create', InventoryTransaction::class);
        
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $data['created_by'] = $request->user()->id;
        
        $transaction = $this->createAction->execute($data);
        
        return response()->json(new InventoryTransactionResource($transaction), 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $transaction = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$transaction) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('view', $transaction);
        
        return response()->json(new InventoryTransactionResource($transaction));
    }

    public function update(UpdateInventoryTransactionRequest $request, string $id): JsonResponse
    {
        $transaction = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$transaction) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('update', $transaction);
        
        $updated = $this->updateAction->execute($transaction, $request->validated());
        
        return response()->json(new InventoryTransactionResource($updated));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $transaction = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$transaction) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('delete', $transaction);
        
        $this->deleteAction->execute($transaction);
        
        return response()->json(null, 204);
    }
}
