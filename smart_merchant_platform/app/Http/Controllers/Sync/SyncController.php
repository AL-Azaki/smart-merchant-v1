<?php

namespace App\Http\Controllers\Sync;

use App\Http\Controllers\Controller;
use App\Services\Sync\SyncEngine;
use App\Services\Sync\SyncContextResolver;
use App\Http\Requests\Sync\PushSyncRequest;
use App\Http\Requests\Sync\PullSyncRequest;
use App\Http\Requests\Sync\AckSyncRequest;
use Illuminate\Http\JsonResponse;

class SyncController extends Controller
{
    public function __construct(
        protected SyncEngine $engine,
        protected SyncContextResolver $contextResolver
    ) {}

    public function push(PushSyncRequest $request): JsonResponse
    {
        $context = $this->contextResolver->resolve($request);
        $result = $this->engine->push($request, $context);
        return response()->json($result);
    }

    public function pull(PullSyncRequest $request): JsonResponse
    {
        $context = $this->contextResolver->resolve($request);
        $result = $this->engine->pull($request, $context);
        return response()->json($result);
    }

    public function ack(AckSyncRequest $request): JsonResponse
    {
        $context = $this->contextResolver->resolve($request);
        $result = $this->engine->ack($request, $context);
        return response()->json($result);
    }
}
