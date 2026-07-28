<?php

namespace Tests\Feature\Sync;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Device;
use App\Models\Order;
use App\Models\ProductUnit;
use App\Models\InventoryProjection;
use Laravel\Sanctum\Sanctum;

class SyncFeatureTest extends TestCase
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

    public function test_push_inventory_projection()
    {
        $category = \App\Models\Category::factory()->create(['business_id' => $this->business->id]);
        $product = \App\Models\Product::factory()->create([
            'business_id' => $this->business->id,
            'category_id' => $category->id
        ]);
        $unit = \App\Models\Unit::factory()->create(['business_id' => $this->business->id]);
        
        $productUnit = \App\Models\ProductUnit::factory()->create([
            'business_id' => $this->business->id,
            'product_id' => $product->id,
            'unit_id' => $unit->id
        ]);
        
        $response = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'inventory_projections',
            'items' => [
                [
                    'id' => \Illuminate\Support\Str::uuid(), // fake uuid
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 10,
                    'revision' => 1,
                    'branch_id' => $this->branch->id
                ]
            ]
        ]);

        $response->assertStatus(200);
        $this->assertEquals(10, InventoryProjection::first()->quantity);
    }

    public function test_pull_online_orders()
    {
        $channel = \App\Models\Channel::factory()->create(['business_id' => $this->business->id]);
        $currency = \App\Models\Currency::factory()->create();

        $order = Order::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'channel_id' => $channel->id,
            'currency_id' => $currency->id,
            'revision' => 5
        ]);

        $response = $this->authenticate()->postJson('/api/sync/pull', [
            'entity' => 'orders',
            'cursor' => 0,
            'limit' => 50
        ]);

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('items'));
        $this->assertEquals($order->id, $response->json('items.0.id'));
    }

    public function test_ack_online_order_idempotency()
    {
        $channel = \App\Models\Channel::factory()->create(['business_id' => $this->business->id]);
        $currency = \App\Models\Currency::factory()->create();

        $order = Order::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'channel_id' => $channel->id,
            'currency_id' => $currency->id,
            'revision' => 5,
            'status' => 'Pending'
        ]);

        $payload = [
            'entity' => 'orders',
            'idempotency_key' => 'idemp-1234',
            'items' => [
                [
                    'id' => $order->id,
                    'revision' => 5
                ]
            ]
        ];

        $response1 = $this->authenticate()->postJson('/api/sync/ack', $payload);
        $response1->assertStatus(200);
        $this->assertEquals('Acknowledged', $order->fresh()->status);

        // Retry same idempotency key
        $response2 = $this->authenticate()->postJson('/api/sync/ack', $payload);
        $response2->assertStatus(200);
        $this->assertEquals('Idempotent replay', $response2->json('message'));
    }

    public function test_reject_forbidden_entity()
    {
        $response = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'users', // Not in pushAllowed
            'items' => [
                [
                    'id' => \Illuminate\Support\Str::uuid(),
                    'revision' => 1
                ]
            ]
        ]);

        $response->assertStatus(403);
    }
}
