<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterDeviceRequest;
use App\Http\Resources\DeviceResource;
use App\Services\DeviceRegistrationService;
use Illuminate\Http\JsonResponse;

class DeviceController extends Controller
{
    protected $deviceService;

    public function __construct(DeviceRegistrationService $deviceService)
    {
        $this->deviceService = $deviceService;
    }

    public function register(RegisterDeviceRequest $request): JsonResponse
    {
        $device = $this->deviceService->register(
            $request->user(),
            $request->input('business_id'),
            $request->input('device_uuid'),
            $request->input('device_name'),
            $request->input('platform'),
            $request->input('app_version')
        );

        return response()->json([
            'message' => 'Device registered successfully',
            'device' => new DeviceResource($device),
        ]);
    }
}
