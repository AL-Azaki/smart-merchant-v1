<?php

namespace App\Domains\Purchasing\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Purchasing\Http\Requests\PurchaseInvoice\CreatePurchaseInvoiceRequest;
use App\Domains\Purchasing\Http\Requests\PurchaseInvoice\UpdatePurchaseInvoiceRequest;
use App\Domains\Purchasing\Actions\PurchaseInvoice\CreatePurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\UpdatePurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\DeletePurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\GetPurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\ListPurchaseInvoicesAction;
use App\Domains\Purchasing\Http\Resources\PurchaseInvoiceResource;
use App\Domains\Purchasing\Http\Resources\PurchaseInvoiceCollection;
use App\Domains\Purchasing\Models\PurchaseInvoice;

class PurchaseInvoiceController extends Controller
{
    use AuthorizesRequests;

    public function __construct(
        private CreatePurchaseInvoiceAction $createAction,
        private UpdatePurchaseInvoiceAction $updateAction,
        private DeletePurchaseInvoiceAction $deleteAction,
        private GetPurchaseInvoiceAction $getAction,
        private ListPurchaseInvoicesAction $listAction
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', PurchaseInvoice::class);
        
        $invoices = $this->listAction->execute($request->user()->business_id);
        
        return response()->json(new PurchaseInvoiceCollection($invoices));
    }

    public function store(CreatePurchaseInvoiceRequest $request): JsonResponse
    {
        $this->authorize('create', PurchaseInvoice::class);
        
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $data['created_by'] = $request->user()->id;
        
        $invoice = $this->createAction->execute($data);
        
        return response()->json(new PurchaseInvoiceResource($invoice), 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $invoice = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$invoice) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('view', $invoice);
        
        return response()->json(new PurchaseInvoiceResource($invoice));
    }

    public function update(UpdatePurchaseInvoiceRequest $request, string $id): JsonResponse
    {
        $invoice = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$invoice) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('update', $invoice);
        
        $updated = $this->updateAction->execute($invoice, $request->validated());
        
        return response()->json(new PurchaseInvoiceResource($updated));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $invoice = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$invoice) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('delete', $invoice);
        
        $this->deleteAction->execute($invoice);
        
        return response()->json(null, 204);
    }
}
