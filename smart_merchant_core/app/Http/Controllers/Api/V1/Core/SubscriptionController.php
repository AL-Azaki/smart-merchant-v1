<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\SubscriptionResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

// Requests
use App\Domains\Core\Requests\StoreSubscriptionRequest;
use App\Domains\Core\Requests\ViewSubscriptionRequest;
use App\Domains\Core\Requests\ListSubscriptionsRequest;
use App\Domains\Core\Requests\SearchSubscriptionsRequest;
use App\Domains\Core\Requests\ActivateSubscriptionRequest;
use App\Domains\Core\Requests\SuspendSubscriptionRequest;
use App\Domains\Core\Requests\CancelSubscriptionRequest;
use App\Domains\Core\Requests\ExpireSubscriptionRequest;
use App\Domains\Core\Requests\CloseSubscriptionRequest;

// DTOs
use App\Domains\Core\DTOs\CreateSubscriptionDTO;
use App\Domains\Core\DTOs\ViewSubscriptionDTO;
use App\Domains\Core\DTOs\SubscriptionListCriteriaDTO;
use App\Domains\Core\DTOs\SubscriptionSearchCriteriaDTO;

// Actions
use App\Domains\Core\Actions\Subscription\CreateSubscriptionAction;
use App\Domains\Core\Actions\Subscription\ViewSubscriptionAction;
use App\Domains\Core\Actions\Subscription\ListSubscriptionsAction;
use App\Domains\Core\Actions\Subscription\SearchSubscriptionsAction;
use App\Domains\Core\Actions\Subscription\ActivateSubscriptionAction;
use App\Domains\Core\Actions\Subscription\SuspendSubscriptionAction;
use App\Domains\Core\Actions\Subscription\CancelSubscriptionAction;
use App\Domains\Core\Actions\Subscription\ExpireSubscriptionAction;
use App\Domains\Core\Actions\Subscription\CloseSubscriptionAction;

class SubscriptionController extends Controller
{
    public function index(string $accountId, ListSubscriptionsRequest $request, ListSubscriptionsAction $action): AnonymousResourceCollection
    {
        $criteria = SubscriptionListCriteriaDTO::fromRequest($request->validated(), $accountId);
        return SubscriptionResource::collection($action->handle($criteria));
    }

    public function search(string $accountId, SearchSubscriptionsRequest $request, SearchSubscriptionsAction $action): AnonymousResourceCollection
    {
        $criteria = SubscriptionSearchCriteriaDTO::fromRequest($request->validated(), $accountId);
        return SubscriptionResource::collection($action->handle($criteria));
    }

    public function show(string $accountId, string $id, ViewSubscriptionRequest $request, ViewSubscriptionAction $action): JsonResponse
    {
        $dto = ViewSubscriptionDTO::fromRequest($request->validated(), $id);
        $subscription = $action->handle($dto, $accountId);
        return response()->json(new SubscriptionResource($subscription));
    }

    public function store(string $accountId, StoreSubscriptionRequest $request, CreateSubscriptionAction $action): JsonResponse
    {
        $dto = CreateSubscriptionDTO::fromRequest($request->validated(), $accountId);
        $subscription = $action->handle($dto);
        return response()->json(new SubscriptionResource($subscription), 201);
    }

    public function activate(string $accountId, string $id, ActivateSubscriptionRequest $request, ActivateSubscriptionAction $action): JsonResponse
    {
        $administrativeReason = $request->validated('administrative_reason');
        $subscription = $action->handle($id, $administrativeReason);
        return response()->json(new SubscriptionResource($subscription));
    }

    public function suspend(string $accountId, string $id, SuspendSubscriptionRequest $request, SuspendSubscriptionAction $action): JsonResponse
    {
        $subscription = $action->handle($id);
        return response()->json(new SubscriptionResource($subscription));
    }

    public function cancel(string $accountId, string $id, CancelSubscriptionRequest $request, CancelSubscriptionAction $action): JsonResponse
    {
        $subscription = $action->handle($id);
        return response()->json(new SubscriptionResource($subscription));
    }

    public function expire(string $accountId, string $id, ExpireSubscriptionRequest $request, ExpireSubscriptionAction $action): JsonResponse
    {
        $subscription = $action->handle($id);
        return response()->json(new SubscriptionResource($subscription));
    }

    public function close(string $accountId, string $id, CloseSubscriptionRequest $request, CloseSubscriptionAction $action): JsonResponse
    {
        $closeReason = $request->validated('close_reason');
        $subscription = $action->handle($id, $closeReason);
        return response()->json(new SubscriptionResource($subscription));
    }
}
