<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Requests\CreatePaymentTermRequest;
use App\Domains\Finance\Requests\UpdatePaymentTermRequest;
use App\Domains\Finance\Requests\PaymentTermSearchRequest;
use App\Domains\Finance\DTOs\CreatePaymentTermDTO;
use App\Domains\Finance\DTOs\UpdatePaymentTermDTO;
use App\Domains\Finance\DTOs\ViewPaymentTermDTO;
use App\Domains\Finance\DTOs\PaymentTermListCriteriaDTO;
use App\Domains\Finance\DTOs\PaymentTermSearchCriteriaDTO;
use App\Domains\Finance\Actions\PaymentTerm\CreatePaymentTermAction;
use App\Domains\Finance\Actions\PaymentTerm\UpdatePaymentTermAction;
use App\Domains\Finance\Actions\PaymentTerm\ViewPaymentTermAction;
use App\Domains\Finance\Actions\PaymentTerm\ListPaymentTermsAction;
use App\Domains\Finance\Actions\PaymentTerm\SearchPaymentTermsAction;
use App\Domains\Finance\Actions\PaymentTerm\ActivatePaymentTermAction;
use App\Domains\Finance\Actions\PaymentTerm\DeactivatePaymentTermAction;
use App\Domains\Finance\Actions\PaymentTerm\DeletePaymentTermAction;
use App\Domains\Finance\Resources\PaymentTermResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class PaymentTermController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListPaymentTermsAction $action): JsonResponse
    {
        $this->authorize('viewAny', PaymentTerm::class);

        $dto = new PaymentTermListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $paymentTerms = $action->handle($dto);

        return PaymentTermResource::collection($paymentTerms)->response();
    }

    public function search(PaymentTermSearchRequest $request, SearchPaymentTermsAction $action): JsonResponse
    {
        $this->authorize('viewAny', PaymentTerm::class);

        $isActive = null;
        if ($request->has('is_active')) {
            $isActive = filter_var($request->input('is_active'), FILTER_VALIDATE_BOOLEAN);
        }

        $dto = new PaymentTermSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            termName: $request->input('term_name'),
            isActive: $isActive,
            perPage: $request->input('per_page', 15)
        );

        $paymentTerms = $action->handle($dto);

        return PaymentTermResource::collection($paymentTerms)->response();
    }

    public function store(CreatePaymentTermRequest $request, CreatePaymentTermAction $action): JsonResponse
    {
        $this->authorize('create', PaymentTerm::class);

        $dto = new CreatePaymentTermDTO(
            businessId: $request->user()->business_id,
            termName: $request->validated('term_name'),
            daysToDue: $request->validated('days_to_due'),
            isActive: true
        );

        $paymentTerm = $action->handle($dto);

        return response()->json([
            'message' => 'Payment term created successfully.',
            'data' => new PaymentTermResource($paymentTerm)
        ], 201);
    }

    public function show(string $id, Request $request, ViewPaymentTermAction $action): JsonResponse
    {
        $dto = new ViewPaymentTermDTO($id, $request->user()->business_id);
        $paymentTerm = $action->handle($dto);
        
        $this->authorize('view', $paymentTerm);

        return response()->json([
            'data' => new PaymentTermResource($paymentTerm)
        ]);
    }

    public function update(string $id, UpdatePaymentTermRequest $request, UpdatePaymentTermAction $action): JsonResponse
    {
        $dto = new ViewPaymentTermDTO($id, $request->user()->business_id);
        $paymentTerm = app(ViewPaymentTermAction::class)->handle($dto);
        
        $this->authorize('update', $paymentTerm);

        $updateDto = new UpdatePaymentTermDTO(
            paymentTermId: $id,
            businessId: $request->user()->business_id,
            termName: $request->validated('term_name'),
            daysToDue: $request->validated('days_to_due')
        );

        $updatedPaymentTerm = $action->handle($updateDto);

        return response()->json([
            'message' => 'Payment term updated successfully.',
            'data' => new PaymentTermResource($updatedPaymentTerm)
        ]);
    }

    public function activate(string $id, Request $request, ActivatePaymentTermAction $action): JsonResponse
    {
        $dto = new ViewPaymentTermDTO($id, $request->user()->business_id);
        $paymentTerm = app(ViewPaymentTermAction::class)->handle($dto);
        
        $this->authorize('update', $paymentTerm);

        $activatedPaymentTerm = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Payment term activated successfully.',
            'data' => new PaymentTermResource($activatedPaymentTerm)
        ]);
    }

    public function deactivate(string $id, Request $request, DeactivatePaymentTermAction $action): JsonResponse
    {
        $dto = new ViewPaymentTermDTO($id, $request->user()->business_id);
        $paymentTerm = app(ViewPaymentTermAction::class)->handle($dto);
        
        $this->authorize('update', $paymentTerm);

        $deactivatedPaymentTerm = $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Payment term deactivated successfully.',
            'data' => new PaymentTermResource($deactivatedPaymentTerm)
        ]);
    }

    public function destroy(string $id, Request $request, DeletePaymentTermAction $action): JsonResponse
    {
        $dto = new ViewPaymentTermDTO($id, $request->user()->business_id);
        $paymentTerm = app(ViewPaymentTermAction::class)->handle($dto);
        
        $this->authorize('delete', $paymentTerm);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Payment term deleted successfully.'
        ]);
    }
}
