<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Requests\CreateFiscalPeriodRequest;
use App\Domains\Finance\Requests\UpdateFiscalPeriodRequest;
use App\Domains\Finance\Requests\FiscalPeriodSearchRequest;
use App\Domains\Finance\DTOs\CreateFiscalPeriodDTO;
use App\Domains\Finance\DTOs\UpdateFiscalPeriodDTO;
use App\Domains\Finance\DTOs\ViewFiscalPeriodDTO;
use App\Domains\Finance\DTOs\FiscalPeriodListCriteriaDTO;
use App\Domains\Finance\DTOs\FiscalPeriodSearchCriteriaDTO;
use App\Domains\Finance\Actions\FiscalPeriod\CreateFiscalPeriodAction;
use App\Domains\Finance\Actions\FiscalPeriod\UpdateFiscalPeriodAction;
use App\Domains\Finance\Actions\FiscalPeriod\ViewFiscalPeriodAction;
use App\Domains\Finance\Actions\FiscalPeriod\ListFiscalPeriodsAction;
use App\Domains\Finance\Actions\FiscalPeriod\SearchFiscalPeriodsAction;
use App\Domains\Finance\Actions\FiscalPeriod\CloseFiscalPeriodAction;
use App\Domains\Finance\Actions\FiscalPeriod\DeleteFiscalPeriodAction;
use App\Domains\Finance\Resources\FiscalPeriodResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class FiscalPeriodController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListFiscalPeriodsAction $action): JsonResponse
    {
        $this->authorize('viewAny', FiscalPeriod::class);

        $dto = new FiscalPeriodListCriteriaDTO(
            businessId: $request->user()->business_id,
            fiscalYearId: $request->input('fiscal_year_id'),
            perPage: $request->input('per_page', 15)
        );

        $fiscalPeriods = $action->handle($dto);

        return FiscalPeriodResource::collection($fiscalPeriods)->response();
    }

    public function search(FiscalPeriodSearchRequest $request, SearchFiscalPeriodsAction $action): JsonResponse
    {
        $this->authorize('viewAny', FiscalPeriod::class);

        $dto = new FiscalPeriodSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            fiscalYearId: $request->input('fiscal_year_id'),
            name: $request->input('name'),
            status: $request->input('status'),
            perPage: $request->input('per_page', 15)
        );

        $fiscalPeriods = $action->handle($dto);

        return FiscalPeriodResource::collection($fiscalPeriods)->response();
    }

    public function store(CreateFiscalPeriodRequest $request, CreateFiscalPeriodAction $action): JsonResponse
    {
        $this->authorize('create', FiscalPeriod::class);

        $dto = new CreateFiscalPeriodDTO(
            businessId: $request->user()->business_id,
            fiscalYearId: $request->validated('fiscal_year_id'),
            periodNumber: $request->validated('period_number'),
            periodName: $request->validated('period_name'),
            startDate: $request->validated('start_date'),
            endDate: $request->validated('end_date')
        );

        $fiscalPeriod = $action->handle($dto);

        return response()->json([
            'message' => 'Fiscal period created successfully.',
            'data' => new FiscalPeriodResource($fiscalPeriod)
        ], 201);
    }

    public function show(string $id, Request $request, ViewFiscalPeriodAction $action): JsonResponse
    {
        $dto = new ViewFiscalPeriodDTO($id, $request->user()->business_id);
        $fiscalPeriod = $action->handle($dto);
        
        $this->authorize('view', $fiscalPeriod);

        return response()->json([
            'data' => new FiscalPeriodResource($fiscalPeriod)
        ]);
    }

    public function update(string $id, UpdateFiscalPeriodRequest $request, UpdateFiscalPeriodAction $action): JsonResponse
    {
        $dto = new ViewFiscalPeriodDTO($id, $request->user()->business_id);
        $fiscalPeriod = app(ViewFiscalPeriodAction::class)->handle($dto);
        
        $this->authorize('update', $fiscalPeriod);

        $updateDto = new UpdateFiscalPeriodDTO(
            fiscalPeriodId: $id,
            businessId: $request->user()->business_id,
            periodName: $request->validated('period_name'),
            startDate: $request->validated('start_date'),
            endDate: $request->validated('end_date')
        );

        $updatedFiscalPeriod = $action->handle($updateDto);

        return response()->json([
            'message' => 'Fiscal period updated successfully.',
            'data' => new FiscalPeriodResource($updatedFiscalPeriod)
        ]);
    }

    public function close(string $id, Request $request, CloseFiscalPeriodAction $action): JsonResponse
    {
        $dto = new ViewFiscalPeriodDTO($id, $request->user()->business_id);
        $fiscalPeriod = app(ViewFiscalPeriodAction::class)->handle($dto);
        
        $this->authorize('update', $fiscalPeriod);

        $closedFiscalPeriod = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Fiscal period closed successfully.',
            'data' => new FiscalPeriodResource($closedFiscalPeriod)
        ]);
    }

    public function destroy(string $id, Request $request, DeleteFiscalPeriodAction $action): JsonResponse
    {
        $dto = new ViewFiscalPeriodDTO($id, $request->user()->business_id);
        $fiscalPeriod = app(ViewFiscalPeriodAction::class)->handle($dto);
        
        $this->authorize('delete', $fiscalPeriod);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Fiscal period deleted successfully.'
        ]);
    }
}
