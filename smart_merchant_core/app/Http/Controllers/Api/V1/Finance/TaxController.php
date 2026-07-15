<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\Requests\CreateTaxRequest;
use App\Domains\Finance\Requests\UpdateTaxRequest;
use App\Domains\Finance\Requests\TaxSearchRequest;
use App\Domains\Finance\DTOs\CreateTaxDTO;
use App\Domains\Finance\DTOs\UpdateTaxDTO;
use App\Domains\Finance\DTOs\ViewTaxDTO;
use App\Domains\Finance\DTOs\TaxListCriteriaDTO;
use App\Domains\Finance\DTOs\TaxSearchCriteriaDTO;
use App\Domains\Finance\Actions\Tax\CreateTaxAction;
use App\Domains\Finance\Actions\Tax\UpdateTaxAction;
use App\Domains\Finance\Actions\Tax\ViewTaxAction;
use App\Domains\Finance\Actions\Tax\ListTaxesAction;
use App\Domains\Finance\Actions\Tax\SearchTaxesAction;
use App\Domains\Finance\Actions\Tax\ActivateTaxAction;
use App\Domains\Finance\Actions\Tax\DeactivateTaxAction;
use App\Domains\Finance\Actions\Tax\DeleteTaxAction;
use App\Domains\Finance\Resources\TaxResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class TaxController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListTaxesAction $action): JsonResponse
    {
        $this->authorize('viewAny', Tax::class);

        $dto = new TaxListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $taxes = $action->handle($dto);

        return TaxResource::collection($taxes)->response();
    }

    public function search(TaxSearchRequest $request, SearchTaxesAction $action): JsonResponse
    {
        $this->authorize('viewAny', Tax::class);

        $isActive = null;
        if ($request->has('is_active')) {
            $isActive = filter_var($request->input('is_active'), FILTER_VALIDATE_BOOLEAN);
        }

        $dto = new TaxSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            taxName: $request->input('tax_name'),
            isActive: $isActive,
            perPage: $request->input('per_page', 15)
        );

        $taxes = $action->handle($dto);

        return TaxResource::collection($taxes)->response();
    }

    public function store(CreateTaxRequest $request, CreateTaxAction $action): JsonResponse
    {
        $this->authorize('create', Tax::class);

        $dto = new CreateTaxDTO(
            businessId: $request->user()->business_id,
            taxName: $request->validated('tax_name'),
            taxRate: $request->validated('tax_rate'),
            isActive: true
        );

        $tax = $action->handle($dto);

        return response()->json([
            'message' => 'Tax created successfully.',
            'data' => new TaxResource($tax)
        ], 201);
    }

    public function show(string $id, Request $request, ViewTaxAction $action): JsonResponse
    {
        $dto = new ViewTaxDTO($id, $request->user()->business_id);
        $tax = $action->handle($dto);
        
        $this->authorize('view', $tax);

        return response()->json([
            'data' => new TaxResource($tax)
        ]);
    }

    public function update(string $id, UpdateTaxRequest $request, UpdateTaxAction $action): JsonResponse
    {
        $dto = new ViewTaxDTO($id, $request->user()->business_id);
        $tax = app(ViewTaxAction::class)->handle($dto);
        
        $this->authorize('update', $tax);

        $updateDto = new UpdateTaxDTO(
            taxId: $id,
            businessId: $request->user()->business_id,
            taxName: $request->validated('tax_name'),
            taxRate: $request->validated('tax_rate')
        );

        $updatedTax = $action->handle($updateDto);

        return response()->json([
            'message' => 'Tax updated successfully.',
            'data' => new TaxResource($updatedTax)
        ]);
    }

    public function activate(string $id, Request $request, ActivateTaxAction $action): JsonResponse
    {
        $dto = new ViewTaxDTO($id, $request->user()->business_id);
        $tax = app(ViewTaxAction::class)->handle($dto);
        
        $this->authorize('update', $tax);

        $activatedTax = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Tax activated successfully.',
            'data' => new TaxResource($activatedTax)
        ]);
    }

    public function deactivate(string $id, Request $request, DeactivateTaxAction $action): JsonResponse
    {
        $dto = new ViewTaxDTO($id, $request->user()->business_id);
        $tax = app(ViewTaxAction::class)->handle($dto);
        
        $this->authorize('update', $tax);

        $deactivatedTax = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Tax deactivated successfully.',
            'data' => new TaxResource($deactivatedTax)
        ]);
    }

    public function destroy(string $id, Request $request, DeleteTaxAction $action): JsonResponse
    {
        $dto = new ViewTaxDTO($id, $request->user()->business_id);
        $tax = app(ViewTaxAction::class)->handle($dto);
        
        $this->authorize('delete', $tax);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Tax deleted successfully.'
        ]);
    }
}
