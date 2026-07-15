<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\ExchangeRate;
use App\Domains\Finance\Requests\CreateExchangeRateRequest;
use App\Domains\Finance\Requests\UpdateExchangeRateRequest;
use App\Domains\Finance\Requests\ExchangeRateSearchRequest;
use App\Domains\Finance\DTOs\CreateExchangeRateDTO;
use App\Domains\Finance\DTOs\UpdateExchangeRateDTO;
use App\Domains\Finance\DTOs\ViewExchangeRateDTO;
use App\Domains\Finance\DTOs\ExchangeRateListCriteriaDTO;
use App\Domains\Finance\DTOs\ExchangeRateSearchCriteriaDTO;
use App\Domains\Finance\Actions\ExchangeRate\CreateExchangeRateAction;
use App\Domains\Finance\Actions\ExchangeRate\UpdateExchangeRateAction;
use App\Domains\Finance\Actions\ExchangeRate\ViewExchangeRateAction;
use App\Domains\Finance\Actions\ExchangeRate\ListExchangeRatesAction;
use App\Domains\Finance\Actions\ExchangeRate\SearchExchangeRatesAction;
use App\Domains\Finance\Actions\ExchangeRate\DeleteExchangeRateAction;
use App\Domains\Finance\Resources\ExchangeRateResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class ExchangeRateController extends Controller
{
    use AuthorizesRequests;

    public function index(Request $request, ListExchangeRatesAction $action): JsonResponse
    {
        $this->authorize('viewAny', ExchangeRate::class);

        $dto = new ExchangeRateListCriteriaDTO(
            businessId: $request->user()->business_id,
            perPage: $request->input('per_page', 15)
        );

        $exchangeRates = $action->handle($dto);

        return ExchangeRateResource::collection($exchangeRates)->response();
    }

    public function search(ExchangeRateSearchRequest $request, SearchExchangeRatesAction $action): JsonResponse
    {
        $this->authorize('viewAny', ExchangeRate::class);

        $dto = new ExchangeRateSearchCriteriaDTO(
            businessId: $request->user()->business_id,
            sourceCurrencyId: $request->input('source_currency_id'),
            targetCurrencyId: $request->input('target_currency_id'),
            effectiveDate: $request->input('effective_date'),
            perPage: $request->input('per_page', 15)
        );

        $exchangeRates = $action->handle($dto);

        return ExchangeRateResource::collection($exchangeRates)->response();
    }

    public function store(CreateExchangeRateRequest $request, CreateExchangeRateAction $action): JsonResponse
    {
        $this->authorize('create', ExchangeRate::class);

        $dto = new CreateExchangeRateDTO(
            businessId: $request->user()->business_id,
            sourceCurrencyId: $request->validated('source_currency_id'),
            targetCurrencyId: $request->validated('target_currency_id'),
            effectiveDate: $request->validated('effective_date'),
            rate: $request->validated('rate')
        );

        $exchangeRate = $action->handle($dto);

        return response()->json([
            'message' => 'Exchange rate created successfully.',
            'data' => new ExchangeRateResource($exchangeRate)
        ], 201);
    }

    public function show(string $id, Request $request, ViewExchangeRateAction $action): JsonResponse
    {
        $dto = new ViewExchangeRateDTO($id, $request->user()->business_id);
        $exchangeRate = $action->handle($dto);
        
        $this->authorize('view', $exchangeRate);

        return response()->json([
            'data' => new ExchangeRateResource($exchangeRate)
        ]);
    }

    public function update(string $id, UpdateExchangeRateRequest $request, UpdateExchangeRateAction $action): JsonResponse
    {
        $dto = new ViewExchangeRateDTO($id, $request->user()->business_id);
        $exchangeRate = app(ViewExchangeRateAction::class)->handle($dto);
        
        $this->authorize('update', $exchangeRate);

        $updateDto = new UpdateExchangeRateDTO(
            exchangeRateId: $id,
            businessId: $request->user()->business_id,
            sourceCurrencyId: $request->validated('source_currency_id'),
            targetCurrencyId: $request->validated('target_currency_id'),
            effectiveDate: $request->validated('effective_date'),
            rate: $request->validated('rate')
        );

        $updatedExchangeRate = $action->handle($updateDto);

        return response()->json([
            'message' => 'Exchange rate updated successfully.',
            'data' => new ExchangeRateResource($updatedExchangeRate)
        ]);
    }

    public function destroy(string $id, Request $request, DeleteExchangeRateAction $action): JsonResponse
    {
        $dto = new ViewExchangeRateDTO($id, $request->user()->business_id);
        $exchangeRate = app(ViewExchangeRateAction::class)->handle($dto);
        
        $this->authorize('delete', $exchangeRate);

        $action->handle($id, $request->user()->business_id);

        return response()->json([
            'message' => 'Exchange rate deleted successfully.'
        ]);
    }
}
