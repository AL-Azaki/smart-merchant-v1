<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\CurrencyResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

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
    public function index(ListCurrenciesRequest $request, ListCurrenciesAction $action): AnonymousResourceCollection
    {
        $criteria = CurrencyListCriteriaDTO::fromRequest($request->validated());
        return CurrencyResource::collection($action->handle($criteria));
    }

    public function search(SearchCurrenciesRequest $request, SearchCurrenciesAction $action): AnonymousResourceCollection
    {
        $criteria = CurrencySearchCriteriaDTO::fromRequest($request->validated());
        return CurrencyResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewCurrencyRequest $request, ViewCurrencyAction $action): JsonResponse
    {
        $dto = ViewCurrencyDTO::fromRequest($request->validated(), $id);
        $currency = $action->handle($dto);
        return response()->json(new CurrencyResource($currency));
    }

    public function store(StoreCurrencyRequest $request, CreateCurrencyAction $action): JsonResponse
    {
        $dto = CreateCurrencyDTO::fromRequest($request->validated());
        $currency = $action->handle($dto);
        return response()->json(new CurrencyResource($currency), 201);
    }

    public function update(string $id, UpdateCurrencyRequest $request, UpdateCurrencyAction $action): JsonResponse
    {
        $dto = UpdateCurrencyDTO::fromRequest($request->validated());
        $currency = $action->handle($id, $dto);
        return response()->json(new CurrencyResource($currency));
    }

    public function destroy(string $id, DeleteCurrencyRequest $request, DeleteCurrencyAction $action): JsonResponse
    {
        $action->handle($id);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateCurrencyRequest $request, ActivateCurrencyAction $action): JsonResponse
    {
        $currency = $action->handle($id);
        return response()->json(new CurrencyResource($currency));
    }

    public function deactivate(string $id, DeactivateCurrencyRequest $request, DeactivateCurrencyAction $action): JsonResponse
    {
        $currency = $action->handle($id);
        return response()->json(new CurrencyResource($currency));
    }

    public function setDefault(string $id, SetDefaultCurrencyRequest $request, SetDefaultCurrencyAction $action): JsonResponse
    {
        $currency = $action->handle($id);
        return response()->json(new CurrencyResource($currency));
    }
}
