<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\PermissionResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

// Requests
use App\Domains\Core\Requests\ViewPermissionRequest;
use App\Domains\Core\Requests\ListPermissionsRequest;
use App\Domains\Core\Requests\SearchPermissionsRequest;

// DTOs
use App\Domains\Core\DTOs\ViewPermissionDTO;
use App\Domains\Core\DTOs\PermissionListCriteriaDTO;
use App\Domains\Core\DTOs\PermissionSearchCriteriaDTO;

// Actions
use App\Domains\Core\Actions\Permission\ViewPermissionAction;
use App\Domains\Core\Actions\Permission\ListPermissionsAction;
use App\Domains\Core\Actions\Permission\SearchPermissionsAction;

class PermissionController extends Controller
{
    // Note: No BusinessId checks because Permission is a System Catalog, not a Business Entity.

    public function index(ListPermissionsRequest $request, ListPermissionsAction $action): AnonymousResourceCollection
    {
        $criteria = PermissionListCriteriaDTO::fromRequest($request->validated());
        return PermissionResource::collection($action->handle($criteria));
    }

    public function search(SearchPermissionsRequest $request, SearchPermissionsAction $action): AnonymousResourceCollection
    {
        $criteria = PermissionSearchCriteriaDTO::fromRequest($request->validated());
        return PermissionResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewPermissionRequest $request, ViewPermissionAction $action): JsonResponse
    {
        $dto = ViewPermissionDTO::fromRequest($request->validated(), $id);
        $permission = $action->handle($dto);
        return response()->json(new PermissionResource($permission));
    }
}
