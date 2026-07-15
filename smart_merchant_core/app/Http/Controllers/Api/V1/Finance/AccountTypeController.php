<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Actions\AccountType\ListAccountTypesAction;
use App\Domains\Finance\Actions\AccountType\ViewAccountTypeAction;
use App\Domains\Finance\DTOs\ViewAccountTypeDTO;
use App\Domains\Finance\Resources\AccountTypeResource;
use Illuminate\Http\JsonResponse;
use App\Domains\Finance\Models\AccountType;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class AccountTypeController extends Controller
{
    use AuthorizesRequests;

    public function index(ListAccountTypesAction $action): JsonResponse
    {
        $this->authorize('viewAny', AccountType::class);

        $accountTypes = $action->handle();

        return response()->json([
            'data' => AccountTypeResource::collection($accountTypes)
        ]);
    }

    public function show(int $id, ViewAccountTypeAction $action): JsonResponse
    {
        $this->authorize('view', AccountType::class);

        $dto = ViewAccountTypeDTO::fromRequest($id);
        
        $accountType = $action->handle($dto);

        return response()->json([
            'data' => new AccountTypeResource($accountType)
        ]);
    }
}
