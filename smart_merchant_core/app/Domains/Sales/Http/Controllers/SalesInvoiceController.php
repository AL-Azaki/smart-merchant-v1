<?php

namespace App\Domains\Sales\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Sales\Http\Requests\SalesInvoice\CreateSalesInvoiceRequest;
use App\Domains\Sales\Http\Requests\SalesInvoice\UpdateSalesInvoiceRequest;
use App\Domains\Sales\Actions\SalesInvoice\CreateSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\UpdateSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\DeleteSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\GetSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\ListSalesInvoicesAction;
use App\Domains\Sales\Http\Resources\SalesInvoiceResource;
use App\Domains\Sales\Http\Resources\SalesInvoiceCollection;

class SalesInvoiceController extends Controller
{
    use AuthorizesRequests;

    public function __construct(
        private CreateSalesInvoiceAction $createAction,
        private UpdateSalesInvoiceAction $updateAction,
        private DeleteSalesInvoiceAction $deleteAction,
        private GetSalesInvoiceAction $getAction,
        private ListSalesInvoicesAction $listAction
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', \App\Domains\Sales\Models\SalesInvoice::class);
        
        $invoices = $this->listAction->execute($request->user()->business_id);
        
        return response()->json(new SalesInvoiceCollection($invoices));
    }

    public function store(CreateSalesInvoiceRequest $request): JsonResponse
    {
        $this->authorize('create', \App\Domains\Sales\Models\SalesInvoice::class);
        
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $data['created_by'] = $request->user()->id;
        
        $invoice = $this->createAction->execute($data);
        
        return response()->json(new SalesInvoiceResource($invoice), 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $invoice = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$invoice) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('view', $invoice);
        
        return response()->json(new SalesInvoiceResource($invoice));
    }

    public function update(UpdateSalesInvoiceRequest $request, string $id): JsonResponse
    {
        $invoice = $this->getAction->execute($request->user()->business_id, $id);
        
        if (!$invoice) {
            return response()->json(['message' => 'Not Found'], 404);
        }

        $this->authorize('update', $invoice);
        
        $updated = $this->updateAction->execute($invoice, $request->validated());
        
        return response()->json(new SalesInvoiceResource($updated));
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
