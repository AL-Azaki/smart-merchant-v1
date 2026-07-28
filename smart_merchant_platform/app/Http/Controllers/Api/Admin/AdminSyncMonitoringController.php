<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use Illuminate\Http\Request;

class AdminSyncMonitoringController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $devices = $business->devices()
            ->orderBy('last_synced_at', 'desc')
            ->take(10)
            ->get();

        $activeDevicesCount = $business->devices()->whereNull('revoked_at')->count();
        $revokedDevicesCount = $business->devices()->whereNotNull('revoked_at')->count();

        return response()->json([
            'data' => [
                'active_devices_count' => $activeDevicesCount,
                'revoked_devices_count' => $revokedDevicesCount,
                'recent_sync_devices' => $devices,
            ]
        ]);
    }
}
