<?php

namespace Tests\Feature\Auth;

use App\Models\Branch;
use App\Models\Business;
use App\Models\Device;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceBindingTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_can_be_registered()
    {
        $business = Business::factory()->create();
        $branch = Branch::factory()->create(['business_id' => $business->id]);
        $user = User::factory()->create(['default_branch_id' => null]);
        $user->branches()->attach($branch->id);

        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/devices/register', [
            'business_id' => $business->id,
            'device_uuid' => 'D-12345',
            'device_name' => 'POS-1',
            'platform' => 'Android',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('device.device_uuid', 'D-12345');

        $this->assertDatabaseHas('devices', [
            'device_uuid' => 'D-12345',
            'business_id' => $business->id,
        ]);
    }

    public function test_device_registration_idempotency()
    {
        $business = Business::factory()->create();
        $branch = Branch::factory()->create(['business_id' => $business->id]);
        $user = User::factory()->create(['default_branch_id' => null]);
        $user->branches()->attach($branch->id);

        $device = Device::factory()->create([
            'business_id' => $business->id,
            'device_uuid' => 'D-12345',
        ]);

        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/devices/register', [
            'business_id' => $business->id,
            'device_uuid' => 'D-12345',
            'device_name' => 'Updated POS',
            'platform' => 'Android',
        ]);

        $response->assertStatus(200);

        // Assert it updated, didn't create a new one
        $this->assertDatabaseCount('devices', 1);
        $this->assertEquals('Updated POS', $device->fresh()->device_name);
    }

    public function test_revoked_device_is_rejected()
    {
        $business = Business::factory()->create();
        $branch = Branch::factory()->create(['business_id' => $business->id]);
        $user = User::factory()->create(['default_branch_id' => null]);
        $user->branches()->attach($branch->id);

        $device = Device::factory()->create([
            'business_id' => $business->id,
            'device_uuid' => 'D-12345',
            'revoked_at' => now(),
        ]);

        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/devices/register', [
            'business_id' => $business->id,
            'device_uuid' => 'D-12345',
        ]);

        $response->assertStatus(422)
            ->assertJsonFragment(['This device is revoked and cannot be registered again.']);
    }
}
