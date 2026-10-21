<?php

namespace Tests\Feature\Sync;

use App\Models\Branch;
use App\Models\Business;
use App\Models\Category;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\Device;
use App\Models\InventoryProjection;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductUnit;
use App\Models\Unit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

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
        $category = Category::factory()->create(['business_id' => $this->business->id]);
        $product = Product::factory()->create([
            'business_id' => $this->business->id,
            'category_id' => $category->id,
        ]);
        $unit = Unit::factory()->create(['business_id' => $this->business->id]);

        $productUnit = ProductUnit::factory()->create([
            'business_id' => $this->business->id,
            'product_id' => $product->id,
            'unit_id' => $unit->id,
        ]);

        $response = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'inventory_projections',
            'items' => [
                [
                    'id' => Str::uuid(), // fake uuid
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 10,
                    'revision' => 1,
                    'branch_id' => $this->branch->id,
                ],
            ],
        ]);

        $response->assertStatus(200);
        $this->assertEquals(10, InventoryProjection::first()->quantity);
    }

    public function test_pull_online_orders()
    {
        $channel = Channel::factory()->create(['business_id' => $this->business->id]);
        $currency = Currency::factory()->create();

        $order = Order::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'channel_id' => $channel->id,
            'currency_id' => $currency->id,
            'revision' => 5,
        ]);

        $response = $this->authenticate()->postJson('/api/sync/pull', [
            'entity' => 'orders',
            'cursor' => 0,
            'limit' => 50,
        ]);

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('items'));
        $this->assertEquals($order->id, $response->json('items.0.id'));
    }

    public function test_ack_online_order_idempotency()
    {
        $channel = Channel::factory()->create(['business_id' => $this->business->id]);
        $currency = Currency::factory()->create();

        $order = Order::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'channel_id' => $channel->id,
            'currency_id' => $currency->id,
            'revision' => 5,
            'status' => 'Pending',
        ]);

        $payload = [
            'entity' => 'orders',
            'idempotency_key' => 'idemp-1234',
            'items' => [
                [
                    'id' => $order->id,
                    'revision' => 5,
                ],
            ],
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
                    'id' => Str::uuid(),
                    'revision' => 1,
                ],
            ],
        ]);

        $response->assertStatus(403);
    }

    public function test_push_product_create_and_full_attribute_update()
    {
        $productId = (string) Str::uuid();

        // 1. Initial Push Create
        $responseCreate = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-SYNC-1',
                    'product_name' => 'Original Product',
                    'product_type' => 'standard',
                    'description' => 'Original Description',
                    'is_active' => true,
                    'show_in_store' => true,
                    'revision' => 1,
                ],
            ],
        ]);

        $responseCreate->assertStatus(200);
        $responseCreate->assertJsonPath('results.0.status', 'applied');

        $this->assertDatabaseHas('products', [
            'id' => $productId,
            'business_id' => $this->business->id,
            'product_name' => 'Original Product',
            'description' => 'Original Description',
            'show_in_store' => true,
            'revision' => 1,
        ]);

        // 2. Push Update with higher revision
        $responseUpdate = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-SYNC-1',
                    'product_name' => 'Updated Product Name',
                    'product_type' => 'standard',
                    'description' => 'Updated Description',
                    'is_active' => true,
                    'show_in_store' => false,
                    'revision' => 2,
                ],
            ],
        ]);

        $responseUpdate->assertStatus(200);
        $responseUpdate->assertJsonPath('results.0.status', 'applied');

        $this->assertDatabaseHas('products', [
            'id' => $productId,
            'business_id' => $this->business->id,
            'product_name' => 'Updated Product Name',
            'description' => 'Updated Description',
            'show_in_store' => false,
            'revision' => 2,
        ]);
    }

    public function test_push_product_unit_with_selling_price_update()
    {
        $product = Product::factory()->create(['business_id' => $this->business->id]);
        $unit = Unit::factory()->create(['business_id' => $this->business->id]);
        $unitId = (string) Str::uuid();

        // 1. Initial Push Create
        $responseCreate = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'product_units',
            'items' => [
                [
                    'id' => $unitId,
                    'product_id' => $product->id,
                    'unit_id' => $unit->id,
                    'barcode' => 'BAR-001',
                    'selling_price' => 150.00,
                    'conversion_factor' => 1.0,
                    'is_base_unit' => true,
                    'is_active' => true,
                    'revision' => 1,
                ],
            ],
        ]);

        $responseCreate->assertStatus(200);
        $responseCreate->assertJsonPath('results.0.status', 'applied');

        $this->assertDatabaseHas('product_units', [
            'id' => $unitId,
            'business_id' => $this->business->id,
            'selling_price' => 150.00,
            'revision' => 1,
        ]);

        // 2. Push Update price to 275.50
        $responseUpdate = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'product_units',
            'items' => [
                [
                    'id' => $unitId,
                    'product_id' => $product->id,
                    'unit_id' => $unit->id,
                    'barcode' => 'BAR-001',
                    'selling_price' => 275.50,
                    'conversion_factor' => 1.0,
                    'is_base_unit' => true,
                    'is_active' => true,
                    'revision' => 2,
                ],
            ],
        ]);

        $responseUpdate->assertStatus(200);
        $responseUpdate->assertJsonPath('results.0.status', 'applied');

        $this->assertDatabaseHas('product_units', [
            'id' => $unitId,
            'business_id' => $this->business->id,
            'selling_price' => 275.50,
            'revision' => 2,
        ]);
    }

    public function test_push_product_soft_delete_and_restore()
    {
        $productId = (string) Str::uuid();

        // 1. Initial Create
        $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-DEL-1',
                    'product_name' => 'To Be Deleted',
                    'is_active' => true,
                    'show_in_store' => true,
                    'revision' => 1,
                ],
            ],
        ])->assertStatus(200);

        $this->assertDatabaseHas('products', [
            'id' => $productId,
            'deleted_at' => null,
            'revision' => 1,
        ]);

        // 2. Soft delete via sync
        $deletedAt = now()->toIso8601String();
        $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-DEL-1',
                    'product_name' => 'To Be Deleted',
                    'is_active' => true,
                    'show_in_store' => true,
                    'deleted_at' => $deletedAt,
                    'revision' => 2,
                ],
            ],
        ])->assertStatus(200);

        $product = Product::withTrashed()->find($productId);
        $this->assertNotNull($product->deleted_at);
        $this->assertTrue($product->trashed());

        // 3. Restore via sync
        $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-DEL-1',
                    'product_name' => 'Restored Product',
                    'is_active' => true,
                    'show_in_store' => true,
                    'deleted_at' => null,
                    'revision' => 3,
                ],
            ],
        ])->assertStatus(200);

        $product->refresh();
        $this->assertNull($product->deleted_at);
        $this->assertFalse($product->trashed());
        $this->assertEquals('Restored Product', $product->product_name);
    }

    public function test_stale_revision_rejected_and_idempotent_replay()
    {
        $productId = (string) Str::uuid();

        // Create with revision 5
        $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-REV-5',
                    'product_name' => 'Rev 5 Name',
                    'revision' => 5,
                ],
            ],
        ])->assertStatus(200);

        // Replay same revision 5 -> idempotent
        $idempResp = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-REV-5',
                    'product_name' => 'Rev 5 Replay',
                    'revision' => 5,
                ],
            ],
        ]);
        $idempResp->assertStatus(200);
        $idempResp->assertJsonPath('results.0.status', 'idempotent');
        $this->assertEquals('Rev 5 Name', Product::find($productId)->product_name);

        // Push older revision 3 -> stale
        $staleResp = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-REV-3',
                    'product_name' => 'Rev 3 Stale',
                    'revision' => 3,
                ],
            ],
        ]);
        $staleResp->assertStatus(200);
        $staleResp->assertJsonPath('results.0.status', 'stale');
        $this->assertEquals('Rev 5 Name', Product::find($productId)->product_name);
    }

    public function test_sync_push_works_when_storefront_active_is_false()
    {
        // Deactivate storefront
        $this->business->update(['storefront_active' => false]);
        $productId = (string) Str::uuid();

        $response = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'products',
            'items' => [
                [
                    'id' => $productId,
                    'product_code' => 'PRD-CLOSED-STORE',
                    'product_name' => 'Synced While Closed',
                    'is_active' => true,
                    'show_in_store' => true,
                    'revision' => 1,
                ],
            ],
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('results.0.status', 'applied');

        $this->assertDatabaseHas('products', [
            'id' => $productId,
            'business_id' => $this->business->id,
            'product_name' => 'Synced While Closed',
            'show_in_store' => true,
        ]);
    }

    public function test_cross_tenant_product_image_push_rejected()
    {
        $otherBusiness = Business::factory()->create();
        $otherProduct = Product::factory()->create(['business_id' => $otherBusiness->id]);
        $imageId = (string) Str::uuid();

        $response = $this->authenticate()->postJson('/api/sync/push', [
            'entity' => 'product_images',
            'items' => [
                [
                    'id' => $imageId,
                    'product_id' => $otherProduct->id,
                    'image_path' => 'https://example.com/img.png',
                    'is_primary' => true,
                    'revision' => 1,
                ],
            ],
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('results.0.status', 'rejected');
        $response->assertJsonPath('results.0.reason', 'parent_product_tenant_mismatch');
    }
}
