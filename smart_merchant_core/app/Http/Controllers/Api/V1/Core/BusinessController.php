<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Requests\CreateBusinessRequest;
use App\Domains\Core\DTOs\CreateBusinessDTO;
use App\Domains\Core\Actions\Business\CreateBusinessAction;
use App\Domains\Core\Resources\BusinessResource;
use Illuminate\Http\JsonResponse;

class BusinessController extends Controller
{
    public function store(CreateBusinessRequest $request, CreateBusinessAction $action): JsonResponse
    {
        $dto = CreateBusinessDTO::fromRequest($request->validated());
        
        $business = $action->handle($dto);
        
        return response()->json(new BusinessResource($business), 201);
    }
    public function show(string $id, \App\Domains\Core\Actions\Business\ViewBusinessAction $action): JsonResponse
    {
        $business = $action->handle($id);
        return response()->json(new BusinessResource($business));
    }

    public function update(string $id, \Illuminate\Http\Request $request, \App\Domains\Core\Actions\Business\ViewBusinessAction $viewAction, \App\Domains\Core\Actions\Business\UpdateBusinessAction $updateAction): JsonResponse
    {
        $business = $viewAction->handle($id);
        $updatedBusiness = $updateAction->handle($business, $request->all());
        return response()->json(new BusinessResource($updatedBusiness));
    }
}
