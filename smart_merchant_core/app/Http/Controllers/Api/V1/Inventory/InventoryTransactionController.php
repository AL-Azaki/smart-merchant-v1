<?php

namespace App\Http\Controllers\Api\V1\Inventory;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Http\Requests\InventoryTransaction\StoreTransactionRequest;
use App\Domains\Inventory\Http\Requests\InventoryTransaction\UpdateTransactionRequest;
use App\Domains\Inventory\Http\Requests\InventoryTransaction\StoreTransactionLineRequest;
use App\Domains\Inventory\Http\Resources\TransactionResource;
use App\Domains\Inventory\Http\Resources\TransactionLineResource;
use App\Domains\Inventory\DTOs\InventoryTransaction\CreateTransactionDTO;
use App\Domains\Inventory\DTOs\InventoryTransaction\UpdateTransactionDTO;
use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionCriteriaDTO;
use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionLineDTO;
use App\Domains\Inventory\Actions\InventoryTransaction\CreateTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\UpdateTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\DeleteTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\GetTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\ListTransactionsAction;
use App\Domains\Inventory\Actions\InventoryTransaction\PostTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\ReverseTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\AddTransactionLineAction;
use App\Domains\Inventory\Actions\InventoryTransaction\UpdateTransactionLineAction;
use App\Domains\Inventory\Actions\InventoryTransaction\DeleteTransactionLineAction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;

class InventoryTransactionController extends Controller
{
    public function index(Request $request, ListTransactionsAction $action): JsonResponse
    {
        $this->authorize('viewAny', InventoryTransaction::class);

        $dto = TransactionCriteriaDTO::fromRequest(array_merge($request->all(), [
            'business_id' => $request->user()->business_id
        ]));

        $paginator = $action->handle($dto);

        return response()->json([
            'data' => TransactionResource::collection($paginator),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total()
            ]
        ]);
    }

    public function store(StoreTransactionRequest $request, CreateTransactionAction $action): JsonResponse
    {
        $this->authorize('create', InventoryTransaction::class);

        $dto = CreateTransactionDTO::fromRequest(array_merge($request->validated(), [
            'business_id' => $request->user()->business_id,
            'created_by' => $request->user()->id
        ]));

        $transaction = $action->handle($dto);

        return response()->json(new TransactionResource($transaction), 201);
    }

    public function show(string $id, Request $request, GetTransactionAction $action): JsonResponse
    {
        $transaction = $action->handle($id, $request->user()->business_id);
        $this->authorize('view', $transaction);

        return response()->json(new TransactionResource($transaction));
    }

    public function update(string $id, UpdateTransactionRequest $request, UpdateTransactionAction $action, GetTransactionAction $getTransaction): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('update', $transaction);

        $dto = UpdateTransactionDTO::fromRequest($request->validated());
        $updatedTransaction = $action->handle($transaction, $dto);

        return response()->json(new TransactionResource($updatedTransaction));
    }

    public function destroy(string $id, Request $request, DeleteTransactionAction $action, GetTransactionAction $getTransaction): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('delete', $transaction);

        $action->handle($transaction);

        return response()->json(null, 204);
    }

    public function post(string $id, Request $request, PostTransactionAction $action, GetTransactionAction $getTransaction): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('post', $transaction);

        $posted = $action->handle($transaction, $request->user()->id);

        return response()->json(new TransactionResource($posted));
    }

    public function reverse(string $id, Request $request, ReverseTransactionAction $action, GetTransactionAction $getTransaction): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('reverse', $transaction);

        $reversed = $action->handle($transaction, $request->user()->id);

        return response()->json(new TransactionResource($reversed));
    }

    public function storeLine(string $id, StoreTransactionLineRequest $request, AddTransactionLineAction $action, GetTransactionAction $getTransaction): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('update', $transaction);

        $dto = TransactionLineDTO::fromRequest($request->validated());
        $line = $action->handle($transaction, $dto);

        return response()->json(new TransactionLineResource($line), 201);
    }

    public function updateLine(string $id, string $lineId, StoreTransactionLineRequest $request, UpdateTransactionLineAction $action, GetTransactionAction $getTransaction, InventoryTransactionRepositoryInterface $repository): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('update', $transaction);

        $line = $repository->findLineById($lineId);
        if (!$line) abort(404);

        $dto = TransactionLineDTO::fromRequest($request->validated());
        $updatedLine = $action->handle($transaction, $line, $dto);

        return response()->json(new TransactionLineResource($updatedLine));
    }

    public function destroyLine(string $id, string $lineId, Request $request, DeleteTransactionLineAction $action, GetTransactionAction $getTransaction, InventoryTransactionRepositoryInterface $repository): JsonResponse
    {
        $transaction = $getTransaction->handle($id, $request->user()->business_id);
        $this->authorize('update', $transaction);

        $line = $repository->findLineById($lineId);
        if (!$line) abort(404);

        $action->handle($transaction, $line);

        return response()->json(null, 204);
    }
}
