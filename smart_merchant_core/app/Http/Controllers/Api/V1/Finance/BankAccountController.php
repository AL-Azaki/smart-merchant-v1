<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Requests\CreateBankAccountRequest;
use App\Domains\Finance\Requests\UpdateBankAccountRequest;
use App\Domains\Finance\Requests\BankAccountSearchRequest;
use App\Domains\Finance\DTOs\CreateBankAccountDTO;
use App\Domains\Finance\DTOs\UpdateBankAccountDTO;
use App\Domains\Finance\DTOs\ViewBankAccountDTO;
use App\Domains\Finance\DTOs\BankAccountListCriteriaDTO;
use App\Domains\Finance\DTOs\BankAccountSearchCriteriaDTO;
use App\Domains\Finance\Actions\BankAccount\CreateBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\UpdateBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\ViewBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\ListBankAccountsAction;
use App\Domains\Finance\Actions\BankAccount\SearchBankAccountsAction;
use App\Domains\Finance\Actions\BankAccount\ActivateBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\DeactivateBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\DeleteBankAccountAction;
use App\Domains\Finance\Resources\BankAccountResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class BankAccountController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListBankAccountsAction $action): JsonResponse
    {
        $this->authorize('viewAny', BankAccount::class);

        $dto = new BankAccountListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $bankAccounts = $action->handle($dto);

        return BankAccountResource::collection($bankAccounts)->response();
    }

    public function search(BankAccountSearchRequest $request, SearchBankAccountsAction $action): JsonResponse
    {
        $this->authorize('viewAny', BankAccount::class);

        $isActive = null;
        if ($request->has('is_active')) {
            $isActive = filter_var($request->input('is_active'), FILTER_VALIDATE_BOOLEAN);
        }

        $dto = new BankAccountSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            bankName: $request->input('bank_name'),
            accountNumber: $request->input('account_number'),
            currencyId: $request->input('currency_id'),
            isActive: $isActive,
            perPage: $request->input('per_page', 15)
        );

        $bankAccounts = $action->handle($dto);

        return BankAccountResource::collection($bankAccounts)->response();
    }

    public function store(CreateBankAccountRequest $request, CreateBankAccountAction $action): JsonResponse
    {
        $this->authorize('create', BankAccount::class);

        $dto = new CreateBankAccountDTO(
            businessId: $request->user()->business_id,
            currencyId: $request->validated('currency_id'),
            accountNumber: $request->validated('account_number'),
            bankName: $request->validated('bank_name'),
            branchId: $request->validated('branch_id'),
            iban: $request->validated('iban'),
            displayName: $request->validated('display_name'),
            description: $request->validated('description'),
            isActive: true,
            isDefault: $request->validated('is_default') ?? false
        );

        $bankAccount = $action->handle($dto);

        return response()->json([
            'message' => 'Bank account created successfully.',
            'data' => new BankAccountResource($bankAccount)
        ], 201);
    }

    public function show(string $id, Request $request, ViewBankAccountAction $action): JsonResponse
    {
        $dto = new ViewBankAccountDTO($id, $request->user()->business_id);
        $bankAccount = $action->handle($dto);
        
        $this->authorize('view', $bankAccount);

        return response()->json([
            'data' => new BankAccountResource($bankAccount)
        ]);
    }

    public function update(string $id, UpdateBankAccountRequest $request, UpdateBankAccountAction $action): JsonResponse
    {
        $dto = new ViewBankAccountDTO($id, $request->user()->business_id);
        $bankAccount = app(ViewBankAccountAction::class)->handle($dto);
        
        $this->authorize('update', $bankAccount);

        $updateDto = new UpdateBankAccountDTO(
            bankAccountId: $id,
            businessId: $request->user()->business_id,
            currencyId: $request->validated('currency_id'),
            accountNumber: $request->validated('account_number'),
            bankName: $request->validated('bank_name'),
            branchId: $request->validated('branch_id'),
            iban: $request->validated('iban'),
            displayName: $request->validated('display_name'),
            description: $request->validated('description'),
            isDefault: $request->validated('is_default') ?? false
        );

        $updatedBankAccount = $action->handle($updateDto);

        return response()->json([
            'message' => 'Bank account updated successfully.',
            'data' => new BankAccountResource($updatedBankAccount)
        ]);
    }

    public function activate(string $id, Request $request, ActivateBankAccountAction $action): JsonResponse
    {
        $dto = new ViewBankAccountDTO($id, $request->user()->business_id);
        $bankAccount = app(ViewBankAccountAction::class)->handle($dto);
        
        $this->authorize('update', $bankAccount);

        $activatedBankAccount = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Bank account activated successfully.',
            'data' => new BankAccountResource($activatedBankAccount)
        ]);
    }

    public function deactivate(string $id, Request $request, DeactivateBankAccountAction $action): JsonResponse
    {
        $dto = new ViewBankAccountDTO($id, $request->user()->business_id);
        $bankAccount = app(ViewBankAccountAction::class)->handle($dto);
        
        $this->authorize('update', $bankAccount);

        $deactivatedBankAccount = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Bank account deactivated successfully.',
            'data' => new BankAccountResource($deactivatedBankAccount)
        ]);
    }

    public function destroy(string $id, Request $request, DeleteBankAccountAction $action): JsonResponse
    {
        $dto = new ViewBankAccountDTO($id, $request->user()->business_id);
        $bankAccount = app(ViewBankAccountAction::class)->handle($dto);
        
        $this->authorize('delete', $bankAccount);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Bank account deleted successfully.'
        ]);
    }
}
