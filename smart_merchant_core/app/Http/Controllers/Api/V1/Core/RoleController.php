<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\RoleResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Request;

// Requests
use App\Domains\Core\Requests\StoreRoleRequest;
use App\Domains\Core\Requests\ViewRoleRequest;
use App\Domains\Core\Requests\ListRolesRequest;
use App\Domains\Core\Requests\SearchRolesRequest;
use App\Domains\Core\Requests\UpdateRoleRequest;
use App\Domains\Core\Requests\DeleteRoleRequest;
use App\Domains\Core\Requests\SyncRolePermissionsRequest;

// DTOs
use App\Domains\Core\DTOs\CreateRoleDTO;
use App\Domains\Core\DTOs\ViewRoleDTO;
use App\Domains\Core\DTOs\RoleListCriteriaDTO;
use App\Domains\Core\DTOs\RoleSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateRoleDTO;
use App\Domains\Core\DTOs\SyncRolePermissionsDTO;

// Actions
use App\Domains\Core\Actions\Role\CreateRoleAction;
use App\Domains\Core\Actions\Role\ViewRoleAction;
use App\Domains\Core\Actions\Role\ListRolesAction;
use App\Domains\Core\Actions\Role\SearchRolesAction;
use App\Domains\Core\Actions\Role\UpdateRoleAction;
use App\Domains\Core\Actions\Role\DeleteRoleAction;
use App\Domains\Core\Actions\Role\SyncRolePermissionsAction;

class RoleController extends Controller
{
    private function getBusinessId(Request $request): string
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) abort(400, 'X-Business-Id header is required.');
        return $businessId;
    }

    public function index(ListRolesRequest $request, ListRolesAction $action): AnonymousResourceCollection
    {
        $businessId = $this->getBusinessId($request);
        $criteria = RoleListCriteriaDTO::fromRequest($request->validated(), $businessId);
        return RoleResource::collection($action->handle($criteria));
    }

    public function search(SearchRolesRequest $request, SearchRolesAction $action): AnonymousResourceCollection
    {
        $businessId = $this->getBusinessId($request);
        $criteria = RoleSearchCriteriaDTO::fromRequest($request->validated(), $businessId);
        return RoleResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewRoleRequest $request, ViewRoleAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = ViewRoleDTO::fromRequest($request->validated(), $id);
        $role = $action->handle($dto, $businessId);
        return response()->json(new RoleResource($role));
    }

    public function store(StoreRoleRequest $request, CreateRoleAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = CreateRoleDTO::fromRequest($request->validated(), $businessId);
        $role = $action->handle($dto);
        return response()->json(new RoleResource($role), 201);
    }

    public function update(string $id, UpdateRoleRequest $request, UpdateRoleAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = UpdateRoleDTO::fromRequest($request->validated());
        $role = $action->handle($id, $businessId, $dto);
        return response()->json(new RoleResource($role));
    }

    public function destroy(string $id, DeleteRoleRequest $request, DeleteRoleAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $action->handle($id, $businessId);
        return response()->json(null, 204);
    }

    public function syncPermissions(string $id, SyncRolePermissionsRequest $request, SyncRolePermissionsAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = SyncRolePermissionsDTO::fromRequest($request->validated(), $id, $businessId);
        $role = $action->handle($dto);
        return response()->json(new RoleResource($role->load('permissions')));
    }
}
