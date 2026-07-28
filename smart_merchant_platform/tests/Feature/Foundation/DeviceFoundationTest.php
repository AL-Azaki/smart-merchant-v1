<?php

namespace Tests\Feature\Foundation;

use App\Models\Business;
use App\Models\Device;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceFoundationTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_is_scoped_to_business()
    {
        $businessA = Business::factory()->create();
        $deviceA = Device::factory()->create(['business_id' => $businessA->id]);

        $businessB = Business::factory()->create();
        $deviceB = Device::factory()->create(['business_id' => $businessB->id]);

        $businessADevices = Device::forBusiness($businessA->id)->get();

        $this->assertTrue($businessADevices->contains('id', $deviceA->id));
        $this->assertFalse($businessADevices->contains('id', $deviceB->id));
    }

    public function test_device_uuid_is_unique_per_business()
    {
        $business = Business::factory()->create();

        Device::factory()->create([
            'business_id' => $business->id,
            'device_uuid' => 'DUUID-123',
        ]);

        $this->expectException(QueryException::class);
        $this->expectExceptionMessageMatches('/unique constraint/i');

        // This should fail at the database level due to the unique constraint
        Device::factory()->create([
            'business_id' => $business->id,
            'device_uuid' => 'DUUID-123',
        ]);
    }
}
