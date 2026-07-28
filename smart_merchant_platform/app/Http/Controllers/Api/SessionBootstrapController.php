<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BootstrapRequest;
use App\Http\Resources\BranchResource;
use App\Http\Resources\BusinessResource;
use App\Http\Resources\DeviceResource;
use App\Http\Resources\UserResource;
use App\Services\SessionBootstrapService;
use Illuminate\Http\JsonResponse;

class SessionBootstrapController extends Controller
{
    protected $bootstrapService;

    public function __construct(SessionBootstrapService $bootstrapService)
    {
        $this->bootstrapService = $bootstrapService;
    }

    public function bootstrap(BootstrapRequest $request): JsonResponse
    {
        $context = $this->bootstrapService->getBootstrapContext(
            $request->user(),
            $request->input('business_id'),
            $request->input('branch_id'),
            $request->input('device_uuid')
        );

        return response()->json([
            'user' => new UserResource($context['user']),
            'active_business' => new BusinessResource($context['active_business']),
            'available_businesses' => BusinessResource::collection($context['available_businesses']),
            'active_branch' => $context['active_branch'] ? new BranchResource($context['active_branch']) : null,
            'allowed_branches' => BranchResource::collection($context['allowed_branches']),
            'roles' => $context['roles'],
            'permissions' => $context['permissions'],
            'subscription' => $context['subscription'] ? [
                'id' => $context['subscription']->id,
                'status' => $context['subscription']->status,
                'plan' => $context['subscription']->plan ? $context['subscription']->plan->plan_name : null,
                'ends_at' => $context['subscription']->end_date,
            ] : null,
            'device' => $context['device'] ? new DeviceResource($context['device']) : null,
        ]);
    }
}
