<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Device;
use Illuminate\Http\Request;

class AdminDeviceController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $devices = $business->devices()->paginate(20);
        return response()->json($devices);
    }

    public function show(Request $request, Business $business, Device $device)
    {
        if ($device->business_id !== $business->id) {
            abort(404);
        }
        return response()->json(['data' => $device]);
    }

    public function update(Request $request, Business $business, Device $device)
    {
        if ($device->business_id !== $business->id) {
            abort(404);
        }

        $validated = $request->validate([
            'device_name' => 'sometimes|string|max:255',
        ]);

        $device->update($validated);

        return response()->json(['data' => $device->refresh()]);
    }

    public function destroy(Request $request, Business $business, Device $device)
    {
        if ($device->business_id !== $business->id) {
            abort(404);
        }

        // Revoke the device
        $device->update(['revoked_at' => now()]);

        return response()->json(['message' => 'Device revoked successfully', 'data' => $device->refresh()]);
    }
}
