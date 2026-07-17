<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\CurrencyResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Core\Models\Currency;

// Requests
use App\Domains\Core\Requests\StoreCurrencyRequest;
use App\Domains\Core\Requests\ViewCurrencyRequest;
use App\Domains\Core\Requests\ListCurrenciesRequest;
use App\Domains\Core\Requests\SearchCurrenciesRequest;
use App\Domains\Core\Requests\UpdateCurrencyRequest;
use App\Domains\Core\Requests\DeleteCurrencyRequest;
use App\Domains\Core\Requests\ActivateCurrencyRequest;
use App\Domains\Core\Requests\DeactivateCurrencyRequest;
use App\Domains\Core\Requests\SetDefaultCurrencyRequest;

// DTOs
use App\Domains\Core\DTOs\CreateCurrencyDTO;
use App\Domains\Core\DTOs\ViewCurrencyDTO;
use App\Domains\Core\DTOs\CurrencyListCriteriaDTO;
use App\Domains\Core\DTOs\CurrencySearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateCurrencyDTO;

// Actions
use App\Domains\Core\Actions\Currency\CreateCurrencyAction;
use App\Domains\Core\Actions\Currency\ViewCurrencyAction;
use App\Domains\Core\Actions\Currency\ListCurrenciesAction;
use App\Domains\Core\Actions\Currency\SearchCurrenciesAction;
use App\Domains\Core\Actions\Currency\UpdateCurrencyAction;
use App\Domains\Core\Actions\Currency\DeleteCurrencyAction;
use App\Domains\Core\Actions\Currency\ActivateCurrencyAction;
use App\Domains\Core\Actions\Currency\DeactivateCurrencyAction;
use App\Domains\Core\Actions\Currency\SetDefaultCurrencyAction;

class CurrencyController extends Controller
{
    use AuthorizesRequests;

    public function index(ListCurrenciesRequest $request, ListCurrenciesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Currency::class);
        $criteria = CurrencyListCriteriaDTO::fromRequest($request->validated());
        return CurrencyResource::collection($action->handle($criteria));
    }

    public function search(SearchCurrenciesRequest $request, SearchCurrenciesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Currency::class);
        $criteria = CurrencySearchCriteriaDTO::fromRequest($request->validated());
        return CurrencyResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewCurrencyRequest $request, ViewCurrencyAction $action): JsonResponse
    {
        $dto = ViewCurrencyDTO::fromRequest($request->validated(), $id);
        $currency = $action->handle($dto);
        $this->authorize('view', $currency);
        return response()->json(new CurrencyResource($currency));
    }

    public function store(StoreCurrencyRequest $request, CreateCurrencyAction $action): JsonResponse
    {
        $this->authorize('create', Currency::class);
        $dto = CreateCurrencyDTO::fromRequest($request->validated());
        $currency = $action->handle($dto);
        return response()->json(new CurrencyResource($currency), 201);
    }

    public function update(string $id, UpdateCurrencyRequest $request, UpdateCurrencyAction $action, ViewCurrencyAction $viewAction): JsonResponse
    {
        $viewDto = ViewCurrencyDTO::fromRequest([], $id);
        $currency = $viewAction->handle($viewDto);
        $this->authorize('update', $currency);

        $dto = UpdateCurrencyDTO::fromRequest($request->validated());
        $updatedCurrency = $action->handle($currency, $dto);
        return response()->json(new CurrencyResource($updatedCurrency));
    }

    public function destroy(string $id, DeleteCurrencyRequest $request, DeleteCurrencyAction $action, ViewCurrencyAction $viewAction): JsonResponse
    {
        $viewDto = ViewCurrencyDTO::fromRequest([], $id);
        $currency = $viewAction->handle($viewDto);
        $this->authorize('delete', $currency);

        $action->handle($currency);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateCurrencyRequest $request, ActivateCurrencyAction $action, ViewCurrencyAction $viewAction): JsonResponse
    {
        $viewDto = ViewCurrencyDTO::fromRequest([], $id);
        $currency = $viewAction->handle($viewDto);
        $this->authorize('update', $currency);

        $activatedCurrency = $action->handle($currency);
        return response()->json(new CurrencyResource($activatedCurrency));
    }

    public function deactivate(string $id, DeactivateCurrencyRequest $request, DeactivateCurrencyAction $action, ViewCurrencyAction $viewAction): JsonResponse
    {
        $viewDto = ViewCurrencyDTO::fromRequest([], $id);
        $currency = $viewAction->handle($viewDto);
        $this->authorize('update', $currency);

        $deactivatedCurrency = $action->handle($currency);
        return response()->json(new CurrencyResource($deactivatedCurrency));
    }

    public function setDefault(string $id, SetDefaultCurrencyRequest $request, SetDefaultCurrencyAction $action, ViewCurrencyAction $viewAction): JsonResponse
    {
        $viewDto = ViewCurrencyDTO::fromRequest([], $id);
        $currency = $viewAction->handle($viewDto);
        $this->authorize('update', $currency);

        $updatedCurrency = $action->handle($currency);
        return response()->json(new CurrencyResource($updatedCurrency));
    }
}
