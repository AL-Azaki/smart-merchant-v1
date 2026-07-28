<?php

namespace Tests\Feature\Sync;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Device;
use App\Models\Customer;
use Laravel\Sanctum\Sanctum;
use Illuminate\Support\Str;

class CustomerArabicSyncTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $business;
    protected $branch;
    protected $device;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create();
        $this->business = Business::factory()->create();
        $this->branch = Branch::factory()->create(['business_id' => $this->business->id]);
        
        // Authorize user for this branch/business
        $this->user->branches()->attach($this->branch->id);
        
        $this->device = Device::create([
            'business_id' => $this->business->id,
            'user_id' => $this->user->id,
            'device_uuid' => 'test-device-uuid',
            'device_name' => 'Test POS',
            'platform' => 'android',
        ]);
    }

    protected function authenticate()
    {
        Sanctum::actingAs($this->user);
        return $this->withHeaders([
            'X-Device-ID' => $this->device->device_uuid,
        ]);
    }

    public function test_push_arabic_customer()
    {
        $customerId = Str::uuid()->toString();
        $arabicName = 'بشير العزكي';

        $response = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'customers',
            'items' => [
                [
                    'id' => $customerId,
                    'customer_name' => $arabicName,
                    'phone' => '123456789',
                    'is_active' => true,
                    'revision' => 1
                ]
            ]
        ]);

        if ($response->status() !== 200) {
            dump($response->json());
        }
        $response->assertStatus(200);
        
        $this->assertDatabaseHas('customers', [
            'id' => $customerId,
            'customer_name' => $arabicName,
            'business_id' => $this->business->id,
        ]);
    }
}
