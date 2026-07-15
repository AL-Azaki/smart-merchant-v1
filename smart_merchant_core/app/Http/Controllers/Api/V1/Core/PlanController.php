<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Resources\PlanResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

// Requests
use App\Domains\Core\Requests\StorePlanRequest;
use App\Domains\Core\Requests\ViewPlanRequest;
use App\Domains\Core\Requests\ListPlansRequest;
use App\Domains\Core\Requests\SearchPlansRequest;
use App\Domains\Core\Requests\UpdatePlanRequest;
use App\Domains\Core\Requests\DeletePlanRequest;
use App\Domains\Core\Requests\ActivatePlanRequest;
use App\Domains\Core\Requests\DeactivatePlanRequest;

// DTOs
use App\Domains\Core\DTOs\CreatePlanDTO;
use App\Domains\Core\DTOs\ViewPlanDTO;
use App\Domains\Core\DTOs\PlanListCriteriaDTO;
use App\Domains\Core\DTOs\PlanSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdatePlanDTO;

// Actions
use App\Domains\Core\Actions\Plan\CreatePlanAction;
use App\Domains\Core\Actions\Plan\ViewPlanAction;
use App\Domains\Core\Actions\Plan\ListPlansAction;
use App\Domains\Core\Actions\Plan\SearchPlansAction;
use App\Domains\Core\Actions\Plan\UpdatePlanAction;
use App\Domains\Core\Actions\Plan\DeletePlanAction;
use App\Domains\Core\Actions\Plan\ActivatePlanAction;
use App\Domains\Core\Actions\Plan\DeactivatePlanAction;

class PlanController extends Controller
{
    public function index(ListPlansRequest $request, ListPlansAction $action): AnonymousResourceCollection
    {
        $criteria = PlanListCriteriaDTO::fromRequest($request->validated());
        return PlanResource::collection($action->handle($criteria));
    }

    public function search(SearchPlansRequest $request, SearchPlansAction $action): AnonymousResourceCollection
    {
        $criteria = PlanSearchCriteriaDTO::fromRequest($request->validated());
        return PlanResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewPlanRequest $request, ViewPlanAction $action): JsonResponse
    {
        $dto = ViewPlanDTO::fromRequest($request->validated(), $id);
        $plan = $action->handle($dto);
        return response()->json(new PlanResource($plan));
    }

    public function store(StorePlanRequest $request, CreatePlanAction $action): JsonResponse
    {
        $dto = CreatePlanDTO::fromRequest($request->validated());
        $plan = $action->handle($dto);
        return response()->json(new PlanResource($plan), 201);
    }

    public function update(string $id, UpdatePlanRequest $request, UpdatePlanAction $action): JsonResponse
    {
        $dto = UpdatePlanDTO::fromRequest($request->validated());
        $plan = $action->handle($id, $dto);
        return response()->json(new PlanResource($plan));
    }

    public function destroy(string $id, DeletePlanRequest $request, DeletePlanAction $action): JsonResponse
    {
        $action->handle($id);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivatePlanRequest $request, ActivatePlanAction $action): JsonResponse
    {
        $plan = $action->handle($id);
        return response()->json(new PlanResource($plan));
    }

    public function deactivate(string $id, DeactivatePlanRequest $request, DeactivatePlanAction $action): JsonResponse
    {
        $plan = $action->handle($id);
        return response()->json(new PlanResource($plan));
    }
}
