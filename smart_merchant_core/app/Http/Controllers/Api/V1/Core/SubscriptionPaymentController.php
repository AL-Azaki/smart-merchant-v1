<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\SubscriptionPaymentResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

// Requests
use App\Domains\Core\Requests\StorePaymentIntentRequest;
use App\Domains\Core\Requests\ViewPaymentRequest;
use App\Domains\Core\Requests\ListPaymentsRequest;
use App\Domains\Core\Requests\MarkPaymentSucceededRequest;
use App\Domains\Core\Requests\MarkPaymentFailedRequest;

// DTOs
use App\Domains\Core\DTOs\CreatePaymentIntentDTO;
use App\Domains\Core\DTOs\PaymentListCriteriaDTO;

// Actions
use App\Domains\Core\Actions\SubscriptionPayment\CreatePaymentIntentAction;
use App\Domains\Core\Actions\SubscriptionPayment\ViewPaymentAction;
use App\Domains\Core\Actions\SubscriptionPayment\ListPaymentsAction;
use App\Domains\Core\Actions\SubscriptionPayment\MarkPaymentAsSucceededAction;
use App\Domains\Core\Actions\SubscriptionPayment\MarkPaymentAsFailedAction;

class SubscriptionPaymentController extends Controller
{
    public function index(string $subscriptionId, ListPaymentsRequest $request, ListPaymentsAction $action): AnonymousResourceCollection
    {
        $criteria = PaymentListCriteriaDTO::fromRequest($request->validated(), $subscriptionId);
        return SubscriptionPaymentResource::collection($action->handle($criteria));
    }

    public function show(string $subscriptionId, string $id, ViewPaymentRequest $request, ViewPaymentAction $action): JsonResponse
    {
        $payment = $action->handle($id);
        return response()->json(new SubscriptionPaymentResource($payment));
    }

    public function store(string $subscriptionId, StorePaymentIntentRequest $request, CreatePaymentIntentAction $action): JsonResponse
    {
        $dto = CreatePaymentIntentDTO::fromRequest($request->validated(), $subscriptionId);
        $payment = $action->handle($dto);
        return response()->json(new SubscriptionPaymentResource($payment), 201);
    }

    public function markAsSucceeded(string $subscriptionId, string $id, MarkPaymentSucceededRequest $request, MarkPaymentAsSucceededAction $action): JsonResponse
    {
        $transactionId = $request->validated('transaction_id');
        $receiptUrl = $request->validated('receipt_url');
        
        $payment = $action->handle($id, $transactionId, $receiptUrl);
        return response()->json(new SubscriptionPaymentResource($payment));
    }

    public function markAsFailed(string $subscriptionId, string $id, MarkPaymentFailedRequest $request, MarkPaymentAsFailedAction $action): JsonResponse
    {
        $failureReason = $request->validated('failure_reason');
        $payment = $action->handle($id, $failureReason);
        return response()->json(new SubscriptionPaymentResource($payment));
    }
}
