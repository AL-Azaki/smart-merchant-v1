<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Requests\CreateChartOfAccountRequest;
use App\Domains\Finance\Requests\UpdateChartOfAccountRequest;
use App\Domains\Finance\Requests\ChartOfAccountSearchRequest;
use App\Domains\Finance\DTOs\CreateChartOfAccountDTO;
use App\Domains\Finance\DTOs\UpdateChartOfAccountDTO;
use App\Domains\Finance\DTOs\ViewChartOfAccountDTO;
use App\Domains\Finance\DTOs\ChartOfAccountListCriteriaDTO;
use App\Domains\Finance\DTOs\ChartOfAccountSearchCriteriaDTO;
use App\Domains\Finance\Actions\ChartOfAccount\CreateChartOfAccountAction;
use App\Domains\Finance\Actions\ChartOfAccount\UpdateChartOfAccountAction;
use App\Domains\Finance\Actions\ChartOfAccount\ViewChartOfAccountAction;
use App\Domains\Finance\Actions\ChartOfAccount\ListChartOfAccountsAction;
use App\Domains\Finance\Actions\ChartOfAccount\TreeViewChartOfAccountsAction;
use App\Domains\Finance\Actions\ChartOfAccount\SearchChartOfAccountsAction;
use App\Domains\Finance\Actions\ChartOfAccount\ActivateChartOfAccountAction;
use App\Domains\Finance\Actions\ChartOfAccount\DeactivateChartOfAccountAction;
use App\Domains\Finance\Actions\ChartOfAccount\DeleteChartOfAccountAction;
use App\Domains\Finance\Resources\ChartOfAccountResource;
use App\Domains\Finance\Resources\ChartOfAccountTreeResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class ChartOfAccountController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListChartOfAccountsAction $action): JsonResponse
    {
        $this->authorize('viewAny', ChartOfAccount::class);

        $dto = new ChartOfAccountListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $accounts = $action->handle($dto);

        return ChartOfAccountResource::collection($accounts)->response();
    }

    public function tree(Request $request, TreeViewChartOfAccountsAction $action): JsonResponse
    {
        $this->authorize('viewAny', ChartOfAccount::class);

        $accounts = $action->handle($request->user()->business_id);

        return response()->json([
            'data' => ChartOfAccountTreeResource::collection($accounts)
        ]);
    }

    public function search(ChartOfAccountSearchRequest $request, SearchChartOfAccountsAction $action): JsonResponse
    {
        $this->authorize('viewAny', ChartOfAccount::class);

        $dto = new ChartOfAccountSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            name: $request->input('name'),
            code: $request->input('code'),
            status: $request->has('status') ? filter_var($request->input('status'), FILTER_VALIDATE_BOOLEAN) : null,
            accountTypeId: $request->input('account_type_id'),
            perPage: $request->input('per_page', 15)
        );

        $accounts = $action->handle($dto);

        return ChartOfAccountResource::collection($accounts)->response();
    }

    public function store(CreateChartOfAccountRequest $request, CreateChartOfAccountAction $action): JsonResponse
    {
        $this->authorize('create', ChartOfAccount::class);

        $dto = new CreateChartOfAccountDTO(
            businessId: $request->user()->business_id,
            accountTypeId: $request->validated('account_type_id'),
            accountName: $request->validated('account_name'),
            normalBalance: $request->validated('normal_balance'),
            accountCode: $request->validated('account_code'),
            parentAccountId: $request->validated('parent_account_id'),
            currencyId: $request->validated('currency_id'),
            description: $request->validated('description'),
            accountCategory: $request->validated('account_category'),
            allowPosting: $request->boolean('allow_posting', false),
            isSystem: false,
            isActive: $request->boolean('is_active', true)
        );

        $account = $action->handle($dto);

        return response()->json([
            'message' => 'Chart of Account created successfully.',
            'data' => new ChartOfAccountResource($account)
        ], 201);
    }

    public function show(string $id, Request $request, ViewChartOfAccountAction $action): JsonResponse
    {
        $dto = new ViewChartOfAccountDTO($id, $request->user()->business_id);
        $account = $action->handle($dto);
        
        $this->authorize('view', $account);

        return response()->json([
            'data' => new ChartOfAccountResource($account)
        ]);
    }

    public function update(string $id, UpdateChartOfAccountRequest $request, UpdateChartOfAccountAction $action): JsonResponse
    {
        $dto = new ViewChartOfAccountDTO($id, $request->user()->business_id);
        $account = app(ViewChartOfAccountAction::class)->handle($dto);
        
        $this->authorize('update', $account);

        $updateDto = new UpdateChartOfAccountDTO(
            accountId: $id,
            businessId: $request->user()->business_id,
            accountName: $request->validated('account_name'),
            accountCode: $request->validated('account_code'),
            parentAccountId: $request->validated('parent_account_id'),
            description: $request->validated('description'),
            isActive: $request->boolean('is_active', true)
        );

        $updatedAccount = $action->handle($updateDto);

        return response()->json([
            'message' => 'Chart of Account updated successfully.',
            'data' => new ChartOfAccountResource($updatedAccount)
        ]);
    }

    public function activate(string $id, Request $request, ActivateChartOfAccountAction $action): JsonResponse
    {
        $dto = new ViewChartOfAccountDTO($id, $request->user()->business_id);
        $account = app(ViewChartOfAccountAction::class)->handle($dto);
        
        $this->authorize('update', $account);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Chart of Account activated successfully.'
        ]);
    }

    public function deactivate(string $id, Request $request, DeactivateChartOfAccountAction $action): JsonResponse
    {
        $dto = new ViewChartOfAccountDTO($id, $request->user()->business_id);
        $account = app(ViewChartOfAccountAction::class)->handle($dto);
        
        $this->authorize('update', $account);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Chart of Account deactivated successfully.'
        ]);
    }

    public function destroy(string $id, Request $request, DeleteChartOfAccountAction $action): JsonResponse
    {
        $dto = new ViewChartOfAccountDTO($id, $request->user()->business_id);
        $account = app(ViewChartOfAccountAction::class)->handle($dto);
        
        $this->authorize('delete', $account);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Chart of Account deleted successfully.'
        ]);
    }
}
