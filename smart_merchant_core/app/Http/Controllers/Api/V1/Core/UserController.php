<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

// Requests
use App\Domains\Core\Requests\StoreUserRequest;
use App\Domains\Core\Requests\ViewUserRequest;
use App\Domains\Core\Requests\ListUsersRequest;
use App\Domains\Core\Requests\SearchUsersRequest;
use App\Domains\Core\Requests\UpdateUserRequest;
use App\Domains\Core\Requests\SuspendUserRequest;
use App\Domains\Core\Requests\ActivateUserRequest;
use App\Domains\Core\Requests\SyncUserRolesRequest;
use App\Domains\Core\Requests\SyncUserBranchesRequest;

// DTOs
use App\Domains\Core\DTOs\CreateUserDTO;
use App\Domains\Core\DTOs\ViewUserDTO;
use App\Domains\Core\DTOs\UserListCriteriaDTO;
use App\Domains\Core\DTOs\UserSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateUserDTO;

// Actions
use App\Domains\Core\Actions\User\CreateUserAction;
use App\Domains\Core\Actions\User\ViewUserAction;
use App\Domains\Core\Actions\User\ListUsersAction;
use App\Domains\Core\Actions\User\SearchUsersAction;
use App\Domains\Core\Actions\User\UpdateUserAction;
use App\Domains\Core\Actions\User\SuspendUserAction;
use App\Domains\Core\Actions\User\ActivateUserAction;
use App\Domains\Core\Actions\User\SyncUserRolesAction;
use App\Domains\Core\Actions\User\SyncUserBranchesAction;
use App\Domains\Core\Models\User;

class UserController extends Controller
{
    private function getBusinessId(\Illuminate\Http\Request $request): string
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) abort(400, 'X-Business-Id header is required.');
        return $businessId;
    }

    public function index(ListUsersRequest $request, ListUsersAction $action): AnonymousResourceCollection
    {
        $businessId = $this->getBusinessId($request);
        $criteria = UserListCriteriaDTO::fromRequest($request->validated(), $businessId);
        return UserResource::collection($action->handle($criteria));
    }

    public function search(SearchUsersRequest $request, SearchUsersAction $action): AnonymousResourceCollection
    {
        $businessId = $this->getBusinessId($request);
        $criteria = UserSearchCriteriaDTO::fromRequest($request->validated(), $businessId);
        return UserResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewUserRequest $request, ViewUserAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = ViewUserDTO::fromRequest($request->validated(), $id);
        $user = $action->handle($dto, $businessId);
        return response()->json(new UserResource($user));
    }

    public function store(StoreUserRequest $request, CreateUserAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = CreateUserDTO::fromRequest($request->validated(), $businessId);
        $user = $action->handle($dto);
        return response()->json(new UserResource($user), 201);
    }

    public function update(string $id, UpdateUserRequest $request, UpdateUserAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $dto = UpdateUserDTO::fromRequest($request->validated());
        $user = $action->handle($id, $businessId, $dto);
        return response()->json(new UserResource($user));
    }

    public function suspend(string $id, SuspendUserRequest $request, SuspendUserAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $user = $action->handle($id, $businessId);
        return response()->json(new UserResource($user));
    }

    public function activate(string $id, ActivateUserRequest $request, ActivateUserAction $action): JsonResponse
    {
        $businessId = $this->getBusinessId($request);
        $user = $action->handle($id, $businessId);
        return response()->json(new UserResource($user));
    }

    public function syncRoles(string $id, SyncUserRolesRequest $request, SyncUserRolesAction $action): JsonResponse
    {
        $user = User::findOrFail($id);
        $action->handle($user, $request->validated('role_ids'));
        return response()->json(new UserResource($user->load('roles')));
    }

    public function syncBranches(string $id, SyncUserBranchesRequest $request, SyncUserBranchesAction $action): JsonResponse
    {
        $user = User::findOrFail($id);
        $action->handle($user, $request->validated('branch_ids'));
        return response()->json(new UserResource($user->load('branches')));
    }
}
