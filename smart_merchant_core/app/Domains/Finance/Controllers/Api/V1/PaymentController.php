<?php

namespace App\Domains\Finance\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\Requests\Payment\CreatePaymentRequest;
use App\Domains\Finance\Requests\Payment\UpdatePaymentRequest;
use App\Domains\Finance\Requests\Payment\PostPaymentRequest;
use App\Domains\Finance\Requests\Payment\ReversePaymentRequest;
use App\Domains\Finance\Resources\Payment\PaymentResource;
use App\Domains\Finance\Resources\Payment\PaymentCollection;
use App\Domains\Finance\Actions\Payment\CreatePaymentAction;
use App\Domains\Finance\Actions\Payment\UpdatePaymentAction;
use App\Domains\Finance\Actions\Payment\DeletePaymentAction;
use App\Domains\Finance\Actions\Payment\PostPaymentAction;
use App\Domains\Finance\Actions\Payment\ReversePaymentAction;
use App\Domains\Finance\Actions\Payment\GetPaymentAction;
use App\Domains\Finance\Actions\Payment\ListPaymentsAction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class PaymentController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListPaymentsAction $action): PaymentCollection
    {
        $this->authorize('viewAny', Payment::class);
        $payments = $action->execute($request->user()->business_id, $request->all());
        return new PaymentCollection($payments);
    }

    public function show(Payment $payment, GetPaymentAction $action): PaymentResource
    {
        $this->authorize('view', $payment);
        return new PaymentResource($action->execute($payment->id));
    }

    public function store(CreatePaymentRequest $request, CreatePaymentAction $action): PaymentResource
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $data['created_by'] = $request->user()->id;

        $payment = $action->execute($data);
        return new PaymentResource($payment);
    }

    public function update(UpdatePaymentRequest $request, Payment $payment, UpdatePaymentAction $action): PaymentResource
    {
        $paymentUpdated = $action->execute($payment->id, $request->validated());
        return new PaymentResource($paymentUpdated);
    }

    public function destroy(Payment $payment, DeletePaymentAction $action): JsonResponse
    {
        $this->authorize('delete', $payment);
        $action->execute($payment->id);
        return response()->json(null, 204);
    }

    public function post(PostPaymentRequest $request, Payment $payment, PostPaymentAction $action): PaymentResource
    {
        $postedPayment = $action->execute($payment->id, $request->user()->id);
        return new PaymentResource($postedPayment);
    }

    public function reverse(ReversePaymentRequest $request, Payment $payment, ReversePaymentAction $action): PaymentResource
    {
        $reversedPayment = $action->execute($payment->id, $request->user()->id, $request->validated('reversal_reason'));
        return new PaymentResource($reversedPayment);
    }
}
