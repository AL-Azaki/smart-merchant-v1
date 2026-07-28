<?php

namespace Database\Factories;

use App\Models\Business;
use App\Models\Device;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class DeviceFactory extends Factory
{
    protected $model = Device::class;

    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'device_uuid' => Str::uuid()->toString(),
            'device_name' => 'Test Device',
        ];
    }
}
