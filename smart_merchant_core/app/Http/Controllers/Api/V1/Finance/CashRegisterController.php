<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Requests\CreateCashRegisterRequest;
use App\Domains\Finance\Requests\UpdateCashRegisterRequest;
use App\Domains\Finance\Requests\CashRegisterSearchRequest;
use App\Domains\Finance\DTOs\CreateCashRegisterDTO;
use App\Domains\Finance\DTOs\UpdateCashRegisterDTO;
use App\Domains\Finance\DTOs\ViewCashRegisterDTO;
use App\Domains\Finance\DTOs\CashRegisterListCriteriaDTO;
use App\Domains\Finance\DTOs\CashRegisterSearchCriteriaDTO;
use App\Domains\Finance\Actions\CashRegister\CreateCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\UpdateCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\ViewCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\ListCashRegistersAction;
use App\Domains\Finance\Actions\CashRegister\SearchCashRegistersAction;
use App\Domains\Finance\Actions\CashRegister\ActivateCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\DeactivateCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\DeleteCashRegisterAction;
use App\Domains\Finance\Resources\CashRegisterResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class CashRegisterController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListCashRegistersAction $action): JsonResponse
    {
        $this->authorize('viewAny', CashRegister::class);

        $dto = new CashRegisterListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $cashRegisters = $action->handle($dto);

        return CashRegisterResource::collection($cashRegisters)->response();
    }

    public function search(CashRegisterSearchRequest $request, SearchCashRegistersAction $action): JsonResponse
    {
        $this->authorize('viewAny', CashRegister::class);

        $isActive = null;
        if ($request->has('is_active')) {
            $isActive = filter_var($request->input('is_active'), FILTER_VALIDATE_BOOLEAN);
        }

        $dto = new CashRegisterSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            registerName: $request->input('register_name'),
            branchId: $request->input('branch_id'),
            isActive: $isActive,
            perPage: $request->input('per_page', 15)
        );

        $cashRegisters = $action->handle($dto);

        return CashRegisterResource::collection($cashRegisters)->response();
    }

    public function store(CreateCashRegisterRequest $request, CreateCashRegisterAction $action): JsonResponse
    {
        $this->authorize('create', CashRegister::class);

        $dto = new CreateCashRegisterDTO(
            businessId: $request->user()->business_id,
            branchId: $request->validated('branch_id'),
            registerName: $request->validated('register_name'),
            isActive: true
        );

        $cashRegister = $action->handle($dto);

        return response()->json([
            'message' => 'Cash register created successfully.',
            'data' => new CashRegisterResource($cashRegister)
        ], 201);
    }

    public function show(string $id, Request $request, ViewCashRegisterAction $action): JsonResponse
    {
        $dto = new ViewCashRegisterDTO($id, $request->user()->business_id);
        $cashRegister = $action->handle($dto);
        
        $this->authorize('view', $cashRegister);

        return response()->json([
            'data' => new CashRegisterResource($cashRegister)
        ]);
    }

    public function update(string $id, UpdateCashRegisterRequest $request, UpdateCashRegisterAction $action): JsonResponse
    {
        $dto = new ViewCashRegisterDTO($id, $request->user()->business_id);
        $cashRegister = app(ViewCashRegisterAction::class)->handle($dto);
        
        $this->authorize('update', $cashRegister);

        $updateDto = new UpdateCashRegisterDTO(
            cashRegisterId: $id,
            businessId: $request->user()->business_id,
            branchId: $request->validated('branch_id'),
            registerName: $request->validated('register_name')
        );

        $updatedCashRegister = $action->handle($updateDto);

        return response()->json([
            'message' => 'Cash register updated successfully.',
            'data' => new CashRegisterResource($updatedCashRegister)
        ]);
    }

    public function activate(string $id, Request $request, ActivateCashRegisterAction $action): JsonResponse
    {
        $dto = new ViewCashRegisterDTO($id, $request->user()->business_id);
        $cashRegister = app(ViewCashRegisterAction::class)->handle($dto);
        
        $this->authorize('update', $cashRegister);

        $activatedCashRegister = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Cash register activated successfully.',
            'data' => new CashRegisterResource($activatedCashRegister)
        ]);
    }

    public function deactivate(string $id, Request $request, DeactivateCashRegisterAction $action): JsonResponse
    {
        $dto = new ViewCashRegisterDTO($id, $request->user()->business_id);
        $cashRegister = app(ViewCashRegisterAction::class)->handle($dto);
        
        $this->authorize('update', $cashRegister);

        $deactivatedCashRegister = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Cash register deactivated successfully.',
            'data' => new CashRegisterResource($deactivatedCashRegister)
        ]);
    }

    public function destroy(string $id, Request $request, DeleteCashRegisterAction $action): JsonResponse
    {
        $dto = new ViewCashRegisterDTO($id, $request->user()->business_id);
        $cashRegister = app(ViewCashRegisterAction::class)->handle($dto);
        
        $this->authorize('delete', $cashRegister);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Cash register deleted successfully.'
        ]);
    }
}
