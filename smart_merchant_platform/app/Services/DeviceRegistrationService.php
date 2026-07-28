<?php

namespace App\Services;

use App\Models\Business;
use App\Models\Device;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class DeviceRegistrationService
{
    public function register(User $user, string $businessId, string $deviceUuid, ?string $deviceName, ?string $platform, ?string $appVersion): Device
    {
        // Ensure user belongs to business
        if (! $user->businesses()->where('businesses.id', $businessId)->exists()) {
            throw ValidationException::withMessages(['business_id' => 'Unauthorized business.']);
        }

        $device = Device::where('business_id', $businessId)
            ->where('device_uuid', $deviceUuid)
            ->first();

        if ($device) {
            if ($device->revoked_at) {
                throw ValidationException::withMessages(['device_uuid' => 'This device is revoked and cannot be registered again.']);
            }

            // Update last seen
            $device->update([
                'device_name' => $deviceName ?? $device->device_name,
                'platform' => $platform ?? $device->platform,
                'app_version' => $appVersion ?? $device->app_version,
                'last_synced_at' => now(),
            ]);

            return $device;
        }

        // Create new
        return Device::create([
            'business_id' => $businessId,
            'user_id' => $user->id,
            'device_uuid' => $deviceUuid,
            'device_name' => $deviceName,
            'platform' => $platform,
            'app_version' => $appVersion,
            'last_synced_at' => now(),
        ]);
    }
}
