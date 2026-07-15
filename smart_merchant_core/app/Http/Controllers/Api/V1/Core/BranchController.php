<?php

namespace App\Http\Controllers\Api\V1\Core;

use App\Http\Controllers\Controller;
use App\Domains\Core\Requests\StoreBranchRequest;
use App\Domains\Core\DTOs\CreateBranchDTO;
use App\Domains\Core\Actions\Branch\CreateBranchAction;
use App\Domains\Core\Resources\BranchResource;
use App\Domains\Core\Actions\Branch\ViewBranchAction;
use App\Domains\Core\DTOs\ViewBranchDTO;
use App\Domains\Core\Requests\ViewBranchRequest;
use App\Domains\Core\Actions\Branch\ListBranchesAction;
use App\Domains\Core\DTOs\BranchListCriteriaDTO;
use App\Domains\Core\Requests\ListBranchesRequest;
use App\Domains\Core\Actions\Branch\SearchBranchesAction;
use App\Domains\Core\DTOs\BranchSearchCriteriaDTO;
use App\Domains\Core\Requests\SearchBranchesRequest;
use App\Domains\Core\Actions\Branch\UpdateBranchAction;
use App\Domains\Core\DTOs\UpdateBranchDTO;
use App\Domains\Core\Requests\UpdateBranchRequest;
use App\Domains\Core\Actions\Branch\SetDefaultBranchAction;
use App\Domains\Core\Requests\SetDefaultBranchRequest;
use App\Domains\Core\Actions\Branch\ActivateBranchAction;
use App\Domains\Core\Requests\ActivateBranchRequest;
use App\Domains\Core\Actions\Branch\DeactivateBranchAction;
use App\Domains\Core\Requests\DeactivateBranchRequest;
use App\Domains\Core\Actions\Branch\DeleteBranchAction;
use App\Domains\Core\Requests\DeleteBranchRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BranchController extends Controller
{
    public function index(ListBranchesRequest $request, ListBranchesAction $action): AnonymousResourceCollection
    {
        // Simulating Multi-Tenant context extraction for isolated retrieval
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) {
            abort(400, 'X-Business-Id header is required.');
        }

        $criteria = BranchListCriteriaDTO::fromRequest($request->validated(), $businessId);
        
        $paginator = $action->handle($criteria);
        
        return BranchResource::collection($paginator);
    }

    public function search(SearchBranchesRequest $request, SearchBranchesAction $action): AnonymousResourceCollection
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) {
            abort(400, 'X-Business-Id header is required.');
        }

        $criteria = BranchSearchCriteriaDTO::fromRequest($request->validated(), $businessId);
        
        $paginator = $action->handle($criteria);
        
        return BranchResource::collection($paginator);
    }

    public function store(StoreBranchRequest $request, CreateBranchAction $action): JsonResponse
    {
        $dto = CreateBranchDTO::fromRequest($request->validated());
        
        $branch = $action->handle($dto);
        
        return response()->json(new BranchResource($branch), 201);
    }

    public function show(string $id, ViewBranchRequest $request, ViewBranchAction $action): JsonResponse
    {
        $dto = ViewBranchDTO::fromRequest($request->validated(), $id);
        
        $branch = $action->handle($dto);
        
        return response()->json(new BranchResource($branch));
    }

    public function update(string $id, UpdateBranchRequest $request, UpdateBranchAction $action): JsonResponse
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) {
            abort(400, 'X-Business-Id header is required.');
        }

        $dto = UpdateBranchDTO::fromRequest($request->validated());
        
        $branch = $action->handle($id, $businessId, $dto);
        
        return response()->json(new BranchResource($branch));
    }

    public function setDefault(string $id, SetDefaultBranchRequest $request, SetDefaultBranchAction $action): JsonResponse
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) abort(400, 'X-Business-Id header is required.');

        $branch = $action->handle($id, $businessId);
        return response()->json(new BranchResource($branch));
    }

    public function activate(string $id, ActivateBranchRequest $request, ActivateBranchAction $action): JsonResponse
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) abort(400, 'X-Business-Id header is required.');

        $branch = $action->handle($id, $businessId);
        return response()->json(new BranchResource($branch));
    }

    public function deactivate(string $id, DeactivateBranchRequest $request, DeactivateBranchAction $action): JsonResponse
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) abort(400, 'X-Business-Id header is required.');

        $branch = $action->handle($id, $businessId);
        return response()->json(new BranchResource($branch));
    }

    public function destroy(string $id, DeleteBranchRequest $request, DeleteBranchAction $action): JsonResponse
    {
        $businessId = $request->header('X-Business-Id');
        if (!$businessId) abort(400, 'X-Business-Id header is required.');

        $action->handle($id, $businessId);
        return response()->json(null, 204);
    }
}
