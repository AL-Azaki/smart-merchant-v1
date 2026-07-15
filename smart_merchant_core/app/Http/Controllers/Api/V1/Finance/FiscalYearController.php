<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Requests\CreateFiscalYearRequest;
use App\Domains\Finance\Requests\UpdateFiscalYearRequest;
use App\Domains\Finance\Requests\FiscalYearSearchRequest;
use App\Domains\Finance\DTOs\CreateFiscalYearDTO;
use App\Domains\Finance\DTOs\UpdateFiscalYearDTO;
use App\Domains\Finance\DTOs\ViewFiscalYearDTO;
use App\Domains\Finance\DTOs\FiscalYearListCriteriaDTO;
use App\Domains\Finance\DTOs\FiscalYearSearchCriteriaDTO;
use App\Domains\Finance\Actions\FiscalYear\CreateFiscalYearAction;
use App\Domains\Finance\Actions\FiscalYear\UpdateFiscalYearAction;
use App\Domains\Finance\Actions\FiscalYear\ViewFiscalYearAction;
use App\Domains\Finance\Actions\FiscalYear\ListFiscalYearsAction;
use App\Domains\Finance\Actions\FiscalYear\SearchFiscalYearsAction;
use App\Domains\Finance\Actions\FiscalYear\CloseFiscalYearAction;
use App\Domains\Finance\Actions\FiscalYear\DeleteFiscalYearAction;
use App\Domains\Finance\Resources\FiscalYearResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class FiscalYearController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListFiscalYearsAction $action): JsonResponse
    {
        $this->authorize('viewAny', FiscalYear::class);

        $dto = new FiscalYearListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $fiscalYears = $action->handle($dto);

        return FiscalYearResource::collection($fiscalYears)->response();
    }

    public function search(FiscalYearSearchRequest $request, SearchFiscalYearsAction $action): JsonResponse
    {
        $this->authorize('viewAny', FiscalYear::class);

        $dto = new FiscalYearSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            code: $request->input('code'),
            name: $request->input('name'),
            status: $request->input('status'),
            perPage: $request->input('per_page', 15)
        );

        $fiscalYears = $action->handle($dto);

        return FiscalYearResource::collection($fiscalYears)->response();
    }

    public function store(CreateFiscalYearRequest $request, CreateFiscalYearAction $action): JsonResponse
    {
        $this->authorize('create', FiscalYear::class);

        $dto = new CreateFiscalYearDTO(
            businessId: $request->user()->business_id,
            fiscalYearCode: $request->validated('fiscal_year_code'),
            fiscalYearName: $request->validated('fiscal_year_name'),
            startDate: $request->validated('start_date'),
            endDate: $request->validated('end_date'),
            description: $request->validated('description')
        );

        $fiscalYear = $action->handle($dto);

        return response()->json([
            'message' => 'Fiscal year created successfully.',
            'data' => new FiscalYearResource($fiscalYear)
        ], 201);
    }

    public function show(string $id, Request $request, ViewFiscalYearAction $action): JsonResponse
    {
        $dto = new ViewFiscalYearDTO($id, $request->user()->business_id);
        $fiscalYear = $action->handle($dto);
        
        $this->authorize('view', $fiscalYear);

        return response()->json([
            'data' => new FiscalYearResource($fiscalYear)
        ]);
    }

    public function update(string $id, UpdateFiscalYearRequest $request, UpdateFiscalYearAction $action): JsonResponse
    {
        $dto = new ViewFiscalYearDTO($id, $request->user()->business_id);
        $fiscalYear = app(ViewFiscalYearAction::class)->handle($dto);
        
        $this->authorize('update', $fiscalYear);

        $updateDto = new UpdateFiscalYearDTO(
            fiscalYearId: $id,
            businessId: $request->user()->business_id,
            fiscalYearName: $request->validated('fiscal_year_name'),
            startDate: $request->validated('start_date'),
            endDate: $request->validated('end_date'),
            description: $request->validated('description')
        );

        $updatedFiscalYear = $action->handle($updateDto);

        return response()->json([
            'message' => 'Fiscal year updated successfully.',
            'data' => new FiscalYearResource($updatedFiscalYear)
        ]);
    }

    public function close(string $id, Request $request, CloseFiscalYearAction $action): JsonResponse
    {
        $dto = new ViewFiscalYearDTO($id, $request->user()->business_id);
        $fiscalYear = app(ViewFiscalYearAction::class)->handle($dto);
        
        $this->authorize('update', $fiscalYear);

        $closedFiscalYear = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Fiscal year closed successfully.',
            'data' => new FiscalYearResource($closedFiscalYear)
        ]);
    }

    public function destroy(string $id, Request $request, DeleteFiscalYearAction $action): JsonResponse
    {
        $dto = new ViewFiscalYearDTO($id, $request->user()->business_id);
        $fiscalYear = app(ViewFiscalYearAction::class)->handle($dto);
        
        $this->authorize('delete', $fiscalYear);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Fiscal year deleted successfully.'
        ]);
    }
}
