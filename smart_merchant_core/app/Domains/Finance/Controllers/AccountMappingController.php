<?php

namespace App\Domains\Finance\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Actions\AccountMapping\CreateAccountMappingAction;
use App\Domains\Finance\Actions\AccountMapping\DeleteAccountMappingAction;
use App\Domains\Finance\Actions\AccountMapping\GetAccountMappingAction;
use App\Domains\Finance\Actions\AccountMapping\ListAccountMappingsAction;
use App\Domains\Finance\Actions\AccountMapping\UpdateAccountMappingAction;
use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Requests\AccountMapping\StoreAccountMappingRequest;
use App\Domains\Finance\Requests\AccountMapping\UpdateAccountMappingRequest;
use App\Domains\Finance\Resources\AccountMappingResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AccountMappingController extends Controller
{
    public function index(Request $request, ListAccountMappingsAction $action): JsonResponse
    {
        $businessId = $request->query('business_id');
        if (!$businessId) {
            return response()->json(['message' => 'business_id is required'], 400);
        }

        $this->authorize('viewAny', AccountMapping::class);

        $mappings = $action->execute($businessId);

        return response()->json([
            'data' => AccountMappingResource::collection($mappings)
        ]);
    }

    public function store(StoreAccountMappingRequest $request, CreateAccountMappingAction $action): JsonResponse
    {
        $this->authorize('create', AccountMapping::class);

        $mapping = $action->execute($request->validated());

        return response()->json([
            'data' => new AccountMappingResource($mapping)
        ], 201);
    }

    public function show(string $businessId, string $mappingType, GetAccountMappingAction $action): JsonResponse
    {
        $mapping = $action->execute($businessId, $mappingType);
        
        if (!$mapping) {
            abort(404);
        }

        $this->authorize('view', $mapping);

        return response()->json([
            'data' => new AccountMappingResource($mapping)
        ]);
    }

    public function update(UpdateAccountMappingRequest $request, string $businessId, string $mappingType, GetAccountMappingAction $getAction, UpdateAccountMappingAction $updateAction): JsonResponse
    {
        $mapping = $getAction->execute($businessId, $mappingType);
        
        if (!$mapping) {
            abort(404);
        }

        $this->authorize('update', $mapping);

        $updatedMapping = $updateAction->execute($mapping, $request->validated());

        return response()->json([
            'data' => new AccountMappingResource($updatedMapping)
        ]);
    }

    public function destroy(string $businessId, string $mappingType, GetAccountMappingAction $getAction, DeleteAccountMappingAction $deleteAction): JsonResponse
    {
        $mapping = $getAction->execute($businessId, $mappingType);
        
        if (!$mapping) {
            abort(404);
        }

        $this->authorize('delete', $mapping);

        $deleteAction->execute($mapping);

        return response()->json(null, 204);
    }
}
