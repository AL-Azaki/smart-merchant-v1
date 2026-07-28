<?php

namespace App\Services\Sync;

use Illuminate\Http\Request;
use App\Models\Device;

class SyncContextResolver
{
    public function resolve(Request $request): array
    {
        $user = $request->user();
        if (!$user) {
            abort(401, 'Unauthorized');
        }

        $deviceUuid = $request->header('X-Device-ID');
        if (!$deviceUuid) {
            abort(400, 'Missing X-Device-ID header');
        }

        $device = Device::where('device_uuid', $deviceUuid)
            ->where('user_id', $user->id)
            ->first();

        if (!$device || $device->revoked_at || $device->trashed()) {
            abort(403, 'Device unauthorized or revoked');
        }

        return [
            'user_id' => $user->id,
            'business_id' => $device->business_id,
            'device_id' => $device->id,
            // 'branch_id' might be needed later, but we use device's business for now
        ];
    }
}
