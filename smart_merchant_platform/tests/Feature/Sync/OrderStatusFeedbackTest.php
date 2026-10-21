<?php

namespace Tests\Feature\Sync;

use App\Models\Branch;
use App\Models\Business;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\Device;
use App\Models\IdempotencyKey;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrderStatusFeedbackTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected Business $business;

    protected Branch $branch;

    protected Device $device;

    protected Channel $channel;

    protected Currency $currency;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
        $this->business = Business::factory()->create(['status' => 'Active']);
        $this->branch = Branch::factory()->create(['business_id' => $this->business->id]);
        $this->channel = Channel::factory()->create(['business_id' => $this->business->id]);
        $this->currency = Currency::factory()->create();

        $this->device = Device::create([
            'business_id' => $this->business->id,
            'user_id' => $this->user->id,
            'device_uuid' => 'test-device-uuid-feedback',
            'device_name' => 'POS Terminal 1',
            'platform' => 'android',
        ]);
    }

    protected function authClient()
    {
        Sanctum::actingAs($this->user);

        return $this->withHeaders([
            'X-Device-ID' => $this->device->device_uuid,
        ]);
    }

    protected function createOrder(string $status = 'Acknowledged', ?string $businessId = null): Order
    {
        $bId = $businessId ?? $this->business->id;
        $branchId = ($bId === $this->business->id) ? $this->branch->id : Branch::factory()->create(['business_id' => $bId])->id;
        $channelId = ($bId === $this->business->id) ? $this->channel->id : Channel::factory()->create(['business_id' => $bId])->id;

        return Order::create([
            'business_id' => $bId,
            'branch_id' => $branchId,
            'channel_id' => $channelId,
            'currency_id' => $this->currency->id,
            'customer_name' => 'Original Customer',
            'customer_phone' => '+967770000000',
            'order_number' => 'ORD-'.strtoupper(Str::random(8)),
            'order_date' => now(),
            'sub_total' => 500.00,
            'grand_total' => 500.00,
            'status' => $status,
            'source' => 'storefront',
            'revision' => 1,
        ]);
    }

    public function test_authentication_required(): void
    {
        $order = $this->createOrder('Acknowledged');

        $response = $this->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(401);
    }

    public function test_authorized_device_header_required(): void
    {
        $order = $this->createOrder('Acknowledged');
        Sanctum::actingAs($this->user);

        $response = $this->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(400); // Missing X-Device-ID header
    }

    public function test_tenant_isolation_cannot_access_other_business_order(): void
    {
        $businessB = Business::factory()->create(['status' => 'Active']);
        $orderB = $this->createOrder('Acknowledged', $businessB->id);

        $response = $this->authClient()->postJson("/api/sync/orders/{$orderB->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(404);
    }

    public function test_acknowledged_to_confirmed_allowed(): void
    {
        $order = $this->createOrder('Acknowledged');
        $idemKey = (string) Str::uuid();

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => $idemKey,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'order_id' => $order->id,
                'order_status' => 'Confirmed',
            ]);

        $this->assertEquals('Confirmed', $order->fresh()->status);
    }

    public function test_acknowledged_to_cancelled_allowed(): void
    {
        $order = $this->createOrder('Acknowledged');
        $idemKey = (string) Str::uuid();

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Cancelled',
            'idempotency_key' => $idemKey,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'order_id' => $order->id,
                'order_status' => 'Cancelled',
            ]);

        $this->assertEquals('Cancelled', $order->fresh()->status);
    }

    public function test_confirmed_to_delivered_allowed_with_invoice_reference(): void
    {
        $order = $this->createOrder('Confirmed');
        $idemKey = (string) Str::uuid();
        $completedTime = now()->toISOString();

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Delivered',
            'idempotency_key' => $idemKey,
            'invoice_id' => 'INV-LOCAL-12345',
            'invoice_number' => 'POS-2026-0099',
            'completed_at' => $completedTime,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'order_id' => $order->id,
                'order_status' => 'Delivered',
                'pos_invoice_reference' => 'POS-2026-0099',
            ]);

        $fresh = $order->fresh();
        $this->assertEquals('Delivered', $fresh->status);
        $this->assertEquals('POS-2026-0099', $fresh->pos_invoice_reference);
        $this->assertNotNull($fresh->completed_at);
    }

    public function test_pending_to_delivered_rejected(): void
    {
        $order = $this->createOrder('Pending');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Delivered',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422);
        $this->assertEquals('Pending', $order->fresh()->status);
    }

    public function test_pending_to_confirmed_rejected_without_ack(): void
    {
        $order = $this->createOrder('Pending');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422);
    }

    public function test_cancelled_to_delivered_rejected(): void
    {
        $order = $this->createOrder('Cancelled');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Delivered',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422);
    }

    public function test_delivered_to_confirmed_rejected(): void
    {
        $order = $this->createOrder('Delivered');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422);
    }

    public function test_idempotent_replay_returns_success_without_side_effects(): void
    {
        $order = $this->createOrder('Confirmed');
        $idemKey = (string) Str::uuid();

        // 1st request
        $res1 = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Delivered',
            'idempotency_key' => $idemKey,
            'invoice_number' => 'POS-001',
        ]);
        $res1->assertStatus(200);

        $revision1 = $order->fresh()->revision;

        // 2nd request (replay with same key and status)
        $res2 = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Delivered',
            'idempotency_key' => $idemKey,
            'invoice_number' => 'POS-001',
        ]);
        $res2->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'message' => 'Idempotent replay',
                'order_status' => 'Delivered',
            ]);

        // Revision unchanged, no extra side effect
        $this->assertEquals($revision1, $order->fresh()->revision);
        $this->assertEquals(1, IdempotencyKey::where('idempotency_key', $idemKey)->count());
    }

    public function test_idempotency_key_collision_rejected_with_409(): void
    {
        $order = $this->createOrder('Acknowledged');
        $idemKey = (string) Str::uuid();

        // Used for Confirmed
        $res1 = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => $idemKey,
        ]);
        $res1->assertStatus(200);

        // Same key reused for Cancelled
        $res2 = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Cancelled',
            'idempotency_key' => $idemKey,
        ]);
        $res2->assertStatus(409);
    }

    public function test_new_key_on_already_applied_same_status_is_safe_noop(): void
    {
        $order = $this->createOrder('Delivered');
        $keyA = (string) Str::uuid();

        $res = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Delivered',
            'idempotency_key' => $keyA,
        ]);

        $res->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'message' => 'Order is already in requested status',
                'order_status' => 'Delivered',
            ]);
    }

    public function test_cannot_modify_customer_fields(): void
    {
        $order = $this->createOrder('Acknowledged');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
            'customer_name' => 'Hacked Name',
            'customer_phone' => '+999999999',
            'customer_email' => 'hacked@example.com',
        ]);

        $response->assertStatus(422);
        $this->assertEquals('Original Customer', $order->fresh()->customer_name);
    }

    public function test_cannot_modify_items_or_quantities(): void
    {
        $order = $this->createOrder('Acknowledged');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
            'items' => [
                ['product_unit_id' => (string) Str::uuid(), 'quantity' => 10],
            ],
        ]);

        $response->assertStatus(422);
    }

    public function test_cannot_modify_prices_or_totals(): void
    {
        $order = $this->createOrder('Acknowledged');

        $response = $this->authClient()->postJson("/api/sync/orders/{$order->id}/status", [
            'status' => 'Confirmed',
            'idempotency_key' => (string) Str::uuid(),
            'sub_total' => 0.01,
            'grand_total' => 0.01,
            'business_id' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422);
        $this->assertEquals(500.00, (float) $order->fresh()->grand_total);
    }

    public function test_existing_pull_and_ack_remain_functional(): void
    {
        $order = $this->createOrder('Pending');

        // 1. Pull
        $pullRes = $this->authClient()->postJson('/api/sync/pull', [
            'entity' => 'orders',
            'cursor' => 0,
        ]);
        $pullRes->assertStatus(200);
        $items = $pullRes->json('items');
        $this->assertTrue(collect($items)->contains('id', $order->id));

        // 2. ACK
        $ackRes = $this->authClient()->postJson('/api/sync/ack', [
            'entity' => 'orders',
            'idempotency_key' => (string) Str::uuid(),
            'items' => [
                ['id' => $order->id, 'revision' => 1],
            ],
        ]);
        $ackRes->assertStatus(200);
        $this->assertEquals('Acknowledged', $order->fresh()->status);
    }
}
