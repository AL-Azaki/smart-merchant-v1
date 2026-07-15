<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\AccountResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

// Requests
use App\Domains\Core\Requests\StoreAccountRequest;
use App\Domains\Core\Requests\ViewAccountRequest;
use App\Domains\Core\Requests\ListAccountsRequest;
use App\Domains\Core\Requests\SearchAccountsRequest;
use App\Domains\Core\Requests\UpdateAccountRequest;
use App\Domains\Core\Requests\SuspendAccountRequest;
use App\Domains\Core\Requests\ActivateAccountRequest;
use App\Domains\Core\Requests\CloseAccountRequest;

// DTOs
use App\Domains\Core\DTOs\CreateAccountDTO;
use App\Domains\Core\DTOs\ViewAccountDTO;
use App\Domains\Core\DTOs\AccountListCriteriaDTO;
use App\Domains\Core\DTOs\AccountSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateAccountDTO;

// Actions
use App\Domains\Core\Actions\Account\CreateAccountAction;
use App\Domains\Core\Actions\Account\ViewAccountAction;
use App\Domains\Core\Actions\Account\ListAccountsAction;
use App\Domains\Core\Actions\Account\SearchAccountsAction;
use App\Domains\Core\Actions\Account\UpdateAccountAction;
use App\Domains\Core\Actions\Account\SuspendAccountAction;
use App\Domains\Core\Actions\Account\ActivateAccountAction;
use App\Domains\Core\Actions\Account\CloseAccountAction;

class AccountController extends Controller
{
    public function index(ListAccountsRequest $request, ListAccountsAction $action): AnonymousResourceCollection
    {
        $criteria = AccountListCriteriaDTO::fromRequest($request->validated());
        return AccountResource::collection($action->handle($criteria));
    }

    public function search(SearchAccountsRequest $request, SearchAccountsAction $action): AnonymousResourceCollection
    {
        $criteria = AccountSearchCriteriaDTO::fromRequest($request->validated());
        return AccountResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewAccountRequest $request, ViewAccountAction $action): JsonResponse
    {
        $dto = ViewAccountDTO::fromRequest($request->validated(), $id);
        $account = $action->handle($dto);
        return response()->json(new AccountResource($account));
    }

    public function store(StoreAccountRequest $request, CreateAccountAction $action): JsonResponse
    {
        $dto = CreateAccountDTO::fromRequest($request->validated());
        $account = $action->handle($dto);
        return response()->json(new AccountResource($account), 201);
    }

    public function update(string $id, UpdateAccountRequest $request, UpdateAccountAction $action): JsonResponse
    {
        $dto = UpdateAccountDTO::fromRequest($request->validated());
        $account = $action->handle($id, $dto);
        return response()->json(new AccountResource($account));
    }

    public function suspend(string $id, SuspendAccountRequest $request, SuspendAccountAction $action): JsonResponse
    {
        $account = $action->handle($id);
        return response()->json(new AccountResource($account));
    }

    public function activate(string $id, ActivateAccountRequest $request, ActivateAccountAction $action): JsonResponse
    {
        $account = $action->handle($id);
        return response()->json(new AccountResource($account));
    }

    public function close(string $id, CloseAccountRequest $request, CloseAccountAction $action): JsonResponse
    {
        $account = $action->handle($id);
        return response()->json(new AccountResource($account));
    }
}
