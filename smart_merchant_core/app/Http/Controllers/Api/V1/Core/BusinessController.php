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
}
