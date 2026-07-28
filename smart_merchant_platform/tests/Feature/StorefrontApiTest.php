<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductUnit;
use App\Models\Unit;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\Order;
use App\Models\InventoryProjection;

class StorefrontApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Currency::factory()->create();
    }

    public function test_storefront_bootstrap()
    {
        $business = Business::factory()->create(['storefront_slug' => 'test-store', 'status' => 'Active']);
        
        $response = $this->getJson("/api/storefront/v1/{$business->storefront_slug}/bootstrap");
        
        $response->assertStatus(200)
                 ->assertJsonPath('data.storefront_slug', 'test-store');
    }

    public function test_category_list_excludes_unpublished_and_cross_tenant()
    {
        $businessA = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active']);
        $businessB = Business::factory()->create(['storefront_slug' => 'store-b', 'status' => 'Active']);

        Category::factory()->create(['business_id' => $businessA->id, 'category_name' => 'Active A', 'is_active' => true]);
        Category::factory()->create(['business_id' => $businessA->id, 'category_name' => 'Inactive A', 'is_active' => false]);
        Category::factory()->create(['business_id' => $businessB->id, 'category_name' => 'Active B', 'is_active' => true]);

        $response = $this->getJson("/api/storefront/v1/store-a/categories");
        
        $response->assertStatus(200)
                 ->assertJsonCount(1, 'data')
                 ->assertJsonPath('data.0.category_name', 'Active A');
    }

    public function test_product_list_filters_and_excludes_cross_tenant()
    {
        $businessA = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active']);
        $businessB = Business::factory()->create(['storefront_slug' => 'store-b', 'status' => 'Active']);

        Product::factory()->create(['business_id' => $businessA->id, 'product_name' => 'Prod A', 'is_active' => true]);
        Product::factory()->create(['business_id' => $businessA->id, 'product_name' => 'Hidden A', 'is_active' => false]);
        Product::factory()->create(['business_id' => $businessB->id, 'product_name' => 'Prod B', 'is_active' => true]);

        $response = $this->getJson("/api/storefront/v1/store-a/products");
        
        $response->assertStatus(200)
                 ->assertJsonCount(1, 'data')
                 ->assertJsonPath('data.0.product_name', 'Prod A');
    }

    public function test_product_detail_and_inventory_projection()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active']);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        
        $product = Product::factory()->create(['business_id' => $business->id, 'is_active' => true]);
        $unit = Unit::factory()->create();
        $productUnit = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $product->id, 'unit_id' => $unit->id, 'selling_price' => 150]);
        
        InventoryProjection::create([
            'business_id' => $business->id,
            'branch_id' => $branch->id,
            'product_unit_id' => $productUnit->id,
            'quantity' => 20,
            'revision' => 1
        ]);

        $response = $this->getJson("/api/storefront/v1/store-a/products/{$product->id}?branch_id={$branch->id}");
        
        $response->assertStatus(200)
                 ->assertJsonPath('data.units.0.inventory_quantity', 20)
                 ->assertJsonPath('data.units.0.selling_price', 150);
    }

    public function test_online_order_does_not_deduct_inventory_and_is_idempotent()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active']);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        Channel::factory()->create(['business_id' => $business->id, 'channel_name' => 'Online Store']);
        
        $product = Product::factory()->create(['business_id' => $business->id, 'is_active' => true]);
        $unit = Unit::factory()->create();
        $productUnit = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $product->id, 'unit_id' => $unit->id, 'selling_price' => 150]);
        
        InventoryProjection::create([
            'business_id' => $business->id,
            'branch_id' => $branch->id,
            'product_unit_id' => $productUnit->id,
            'quantity' => 20,
            'revision' => 1
        ]);

        $payload = [
            'idempotency_key' => 'test-key-123',
            'customer_name' => 'John Doe',
            'branch_id' => $branch->id,
            'items' => [
                [
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 5
                ]
            ]
        ];

        $response = $this->postJson("/api/storefront/v1/store-a/orders", $payload);
        $response->assertStatus(201);
        
        // Assert inventory remains unchanged in projection
        $this->assertDatabaseHas('inventory_projections', [
            'product_unit_id' => $productUnit->id,
            'quantity' => 20,
        ]);
        
        // Assert order created
        $this->assertDatabaseHas('orders', [
            'business_id' => $business->id,
        ]);
        
        // Test idempotency
        $response2 = $this->postJson("/api/storefront/v1/store-a/orders", $payload);
        $response2->assertStatus(409); // Idempotency key already used
        
        $this->assertEquals(1, Order::count());
        
        // Test collision
        $payload['customer_name'] = 'Jane Doe';
        $response3 = $this->postJson("/api/storefront/v1/store-a/orders", $payload);
        $response3->assertStatus(409);
    }

    public function test_cross_tenant_order_attack_fails()
    {
        $businessA = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active']);
        $branchA = Branch::factory()->create(['business_id' => $businessA->id, 'is_online_branch' => true]);
        $businessB = Business::factory()->create(['storefront_slug' => 'store-b', 'status' => 'Active']);
        Channel::factory()->create(['business_id' => $businessA->id, 'channel_name' => 'Online Store']);
        
        $productB = Product::factory()->create(['business_id' => $businessB->id, 'is_active' => true]);
        $unit = Unit::factory()->create();
        $productUnitB = ProductUnit::factory()->create(['business_id' => $businessB->id, 'product_id' => $productB->id, 'unit_id' => $unit->id]);

        $payload = [
            'idempotency_key' => 'test-key-456',
            'items' => [
                [
                    'product_unit_id' => $productUnitB->id,
                    'quantity' => 1
                ]
            ]
        ];

        $response = $this->postJson("/api/storefront/v1/store-a/orders", $payload);
        $response->assertStatus(404); // Should fail to find product unit for business A
    }

    public function test_out_of_stock_rejected()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active']);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        Channel::factory()->create(['business_id' => $business->id, 'channel_name' => 'Online Store']);
        
        $product = Product::factory()->create(['business_id' => $business->id, 'is_active' => true]);
        $unit = Unit::factory()->create();
        $productUnit = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $product->id, 'unit_id' => $unit->id, 'selling_price' => 150]);
        
        InventoryProjection::create([
            'business_id' => $business->id,
            'branch_id' => $branch->id,
            'product_unit_id' => $productUnit->id,
            'quantity' => 2,
            'revision' => 1
        ]);

        $payload = [
            'idempotency_key' => 'test-key-oos',
            'branch_id' => $branch->id,
            'items' => [
                [
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 5
                ]
            ]
        ];

        $response = $this->postJson("/api/storefront/v1/store-a/orders", $payload);
        $response->assertStatus(422); // Insufficient inventory
    }
}
