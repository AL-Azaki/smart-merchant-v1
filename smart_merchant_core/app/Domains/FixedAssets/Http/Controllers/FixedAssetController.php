<?php

namespace App\Domains\FixedAssets\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\FixedAssets\Actions\CreateFixedAssetAction;
use App\Domains\FixedAssets\Actions\UpdateFixedAssetAction;
use App\Domains\FixedAssets\Actions\ActivateFixedAssetAction;
use App\Domains\FixedAssets\Actions\DisposeFixedAssetAction;
use App\Domains\FixedAssets\Actions\GenerateDepreciationScheduleAction;
use App\Domains\FixedAssets\Actions\GetFixedAssetAction;
use App\Domains\FixedAssets\Actions\ListFixedAssetsAction;
use App\Domains\FixedAssets\Actions\LoadFixedAssetAggregateAction;
use App\Domains\FixedAssets\Http\Requests\StoreFixedAssetRequest;
use App\Domains\FixedAssets\Http\Requests\UpdateFixedAssetRequest;
use App\Domains\FixedAssets\Http\Resources\FixedAssetResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FixedAssetController extends Controller
{
    public function index(Request $request, ListFixedAssetsAction $action): JsonResponse
    {
        $assets = $action->execute($request->input('business_id'));
        return response()->json(['data' => FixedAssetResource::collection($assets)]);
    }

    public function store(StoreFixedAssetRequest $request, CreateFixedAssetAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['created_by'] = $request->user()->id;
        $asset = $action->execute($data);
        return response()->json(['data' => new FixedAssetResource($asset)], 201);
    }

    public function show(string $id, GetFixedAssetAction $action): JsonResponse
    {
        $asset = $action->execute($id);
        return response()->json(['data' => new FixedAssetResource($asset)]);
    }

    public function update(string $id, UpdateFixedAssetRequest $request, UpdateFixedAssetAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['updated_by'] = $request->user()->id;
        $asset = $action->execute($id, $data);
        return response()->json(['data' => new FixedAssetResource($asset)]);
    }

    public function activate(string $id, Request $request, ActivateFixedAssetAction $action): JsonResponse
    {
        $asset = $action->execute($id, $request->user()->id);
        return response()->json(['data' => new FixedAssetResource($asset)]);
    }

    public function dispose(string $id, Request $request, DisposeFixedAssetAction $action): JsonResponse
    {
        $asset = $action->execute($id, $request->user()->id);
        return response()->json(['data' => new FixedAssetResource($asset)]);
    }

    public function generateSchedule(string $id, Request $request, GenerateDepreciationScheduleAction $action): JsonResponse
    {
        $asset = $action->execute($id, $request->user()->id);
        return response()->json(['data' => new FixedAssetResource($asset)]);
    }

    public function showAggregate(string $id, LoadFixedAssetAggregateAction $action): JsonResponse
    {
        $asset = $action->execute($id);
        return response()->json(['data' => new FixedAssetResource($asset)]);
    }
}
