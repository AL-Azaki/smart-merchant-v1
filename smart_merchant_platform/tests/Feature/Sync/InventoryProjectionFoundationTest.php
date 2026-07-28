<?php

namespace Tests\Feature\Sync;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Product;
use App\Models\ProductUnit;
use App\Models\Unit;
use App\Models\Category;
use App\Models\InventoryProjection;
use App\Models\Order;
use App\Models\OrderItem;
use App\Services\Sync\InventoryProjectionService;
use Illuminate\Database\QueryException;

class InventoryProjectionFoundationTest extends TestCase
{
    use RefreshDatabase;

    protected $business;
    protected $branch;
    protected $productUnit;
    protected $service;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->business = Business::factory()->create();
        $this->branch = Branch::factory()->create(['business_id' => $this->business->id]);
        
        $category = Category::factory()->create(['business_id' => $this->business->id]);
        $product = Product::factory()->create([
            'business_id' => $this->business->id,
            'category_id' => $category->id
        ]);
        
        $unit = Unit::factory()->create(['business_id' => $this->business->id]);
        
        $this->productUnit = ProductUnit::factory()->create([
            'business_id' => $this->business->id,
            'product_id' => $product->id,
            'unit_id' => $unit->id,
        ]);

        $this->service = new InventoryProjectionService();
    }

    /**
     * Test A — Projection Creation
     */
    public function test_authorized_inventory_projection_can_be_persisted()
    {
        $result = $this->service->upsertProjection(
            $this->business->id,
            $this->branch->id,
            $this->productUnit->id,
            20.5000,
            10
        );

        $this->assertEquals('applied', $result['status']);
        
        $projection = InventoryProjection::first();
        $this->assertNotNull($projection);
        $this->assertEquals(20.5000, $projection->quantity);
        $this->assertEquals(10, $projection->revision);
        $this->assertEquals($this->business->id, $projection->business_id);
    }

    /**
     * Test B — Tenant Isolation
     */
    public function test_cannot_create_projection_for_other_business_product_unit()
    {
        $otherBusiness = Business::factory()->create();
        
        $result = $this->service->upsertProjection(
            $otherBusiness->id,
            $this->branch->id, // wrong branch but for this test we focus on product unit check
            $this->productUnit->id, // belongs to $this->business
            20,
            10
        );

        $this->assertEquals('rejected', $result['status']);
        $this->assertEquals('invalid_product_unit_tenant', $result['reason']);
        $this->assertEquals(0, InventoryProjection::count());
    }

    /**
     * Test C — Revision Upgrade
     */
    public function test_newer_revision_upgrades_projection()
    {
        $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 20, 10);
        $result = $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 15, 11);

        $this->assertEquals('applied', $result['status']);
        $this->assertEquals(11, $result['server_revision']);

        $projection = InventoryProjection::first();
        $this->assertEquals(15.0000, $projection->quantity);
        $this->assertEquals(11, $projection->revision);
    }

    /**
     * Test D — Stale Revision
     */
    public function test_stale_revision_does_not_overwrite_newer_projection()
    {
        $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 15, 11);
        $result = $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 18, 10);

        $this->assertEquals('stale', $result['status']);
        $this->assertEquals(11, $result['server_revision']);

        $projection = InventoryProjection::first();
        $this->assertEquals(15.0000, $projection->quantity); // Unchanged
        $this->assertEquals(11, $projection->revision);
    }

    /**
     * Test E — Same Revision Retry
     */
    public function test_same_revision_is_treated_idempotently()
    {
        $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 15, 11);
        $result = $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 15, 11);

        $this->assertEquals('idempotent', $result['status']);
        $this->assertEquals(11, $result['server_revision']);
        $this->assertEquals(1, InventoryProjection::count()); // No duplicate row
    }

    /**
     * Test F — Online Order Isolation
     */
    public function test_online_order_does_not_modify_inventory_projection()
    {
        $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 20, 10);

        $channel = \App\Models\Channel::factory()->create(['business_id' => $this->business->id]);
        $currency = \App\Models\Currency::factory()->create();

        $order = Order::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'channel_id' => $channel->id,
            'currency_id' => $currency->id,
        ]);

        OrderItem::factory()->create([
            'business_id' => $this->business->id,
            'order_id' => $order->id,
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 5,
        ]);

        // Creating order must not trigger observers that modify projection.
        $projection = InventoryProjection::first();
        $this->assertEquals(20.0000, $projection->quantity);
    }

    /**
     * Test G — Order ACK Isolation
     */
    public function test_pulling_or_acking_online_order_does_not_modify_inventory_projection()
    {
        $this->service->upsertProjection($this->business->id, $this->branch->id, $this->productUnit->id, 20, 10);

        $channel = \App\Models\Channel::factory()->create(['business_id' => $this->business->id]);
        $currency = \App\Models\Currency::factory()->create();

        $order = Order::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'channel_id' => $channel->id,
            'currency_id' => $currency->id,
            'status' => 'Pending'
        ]);
        
        // Simulating an ACK (updating the order to acknowledged)
        $order->update(['status' => 'Acknowledged']);

        $projection = InventoryProjection::first();
        $this->assertEquals(20.0000, $projection->quantity);
    }

    /**
     * Test H — PostgreSQL Constraints
     */
    public function test_invalid_foreign_keys_fail_postgresql_constraints()
    {
        $this->expectException(QueryException::class);
        $this->expectExceptionMessageMatches('/foreign key constraint/');

        // Try to insert a raw row that bypasses the service tenant check
        InventoryProjection::create([
            'business_id' => $this->business->id,
            'branch_id' => (string)\Illuminate\Support\Str::uuid(), // Non-existent branch
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 10,
            'revision' => 1
        ]);
    }
}
