<?php

namespace Tests\Feature;

use App\Models\Branch;
use App\Models\Business;
use App\Models\Category;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\InventoryProjection;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductUnit;
use App\Models\Unit;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

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

        $response = $this->getJson('/api/storefront/v1/store-a/categories');

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

        $response = $this->getJson('/api/storefront/v1/store-a/products');

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
            'revision' => 1,
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
            'revision' => 1,
        ]);

        $payload = [
            'idempotency_key' => 'test-key-123',
            'customer_name' => 'John Doe',
            'branch_id' => $branch->id,
            'items' => [
                [
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 5,
                ],
            ],
        ];

        $response = $this->postJson('/api/storefront/v1/store-a/orders', $payload);
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
        $response2 = $this->postJson('/api/storefront/v1/store-a/orders', $payload);
        $response2->assertStatus(409); // Idempotency key already used

        $this->assertEquals(1, Order::count());

        // Test collision
        $payload['customer_name'] = 'Jane Doe';
        $response3 = $this->postJson('/api/storefront/v1/store-a/orders', $payload);
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
                    'quantity' => 1,
                ],
            ],
        ];

        $response = $this->postJson('/api/storefront/v1/store-a/orders', $payload);
        $response->assertStatus(422)
            ->assertJson([
                'code' => 'PRODUCT_UNIT_UNAVAILABLE',
                'message' => 'أحد المنتجات في السلة لم يعد متاحًا للشراء.',
                'errors' => [
                    'items.0.product_unit_id' => [
                        'هذا المنتج أو خيار البيع لم يعد متاحًا.',
                    ],
                ],
            ]);
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
            'revision' => 1,
        ]);

        $payload = [
            'idempotency_key' => 'test-key-oos',
            'branch_id' => $branch->id,
            'items' => [
                [
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 5,
                ],
            ],
        ];

        $response = $this->postJson('/api/storefront/v1/store-a/orders', $payload);
        $response->assertStatus(422); // Insufficient inventory
    }

    public function test_guest_customer_details_are_persisted_in_order()
    {
        $business = Business::factory()->create([
            'storefront_slug' => 'store-guest',
            'status' => 'Active',
            'storefront_active' => true,
        ]);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        Channel::factory()->create(['business_id' => $business->id, 'channel_name' => 'Online Store']);

        $product = Product::factory()->create([
            'business_id' => $business->id,
            'is_active' => true,
            'show_in_store' => true,
        ]);
        $unit = Unit::factory()->create();
        $productUnit = ProductUnit::factory()->create([
            'business_id' => $business->id,
            'product_id' => $product->id,
            'unit_id' => $unit->id,
            'selling_price' => 500,
        ]);

        InventoryProjection::create([
            'business_id' => $business->id,
            'branch_id' => $branch->id,
            'product_unit_id' => $productUnit->id,
            'quantity' => 10,
            'revision' => 1,
        ]);

        $payload = [
            'idempotency_key' => 'guest-key-101',
            'customer_name' => 'بشير العزكي',
            'phone' => '967770000000',
            'email' => 'customer@example.com',
            'address' => 'شارع حدة، صنعاء',
            'city' => 'صنعاء',
            'notes' => 'يرجى الاتصال قبل التوصيل',
            'branch_id' => $branch->id,
            'items' => [
                [
                    'product_unit_id' => $productUnit->id,
                    'quantity' => 2,
                ],
            ],
        ];

        $response = $this->postJson('/api/storefront/v1/store-guest/orders', $payload);
        $response->assertStatus(201);

        $this->assertDatabaseHas('orders', [
            'business_id' => $business->id,
            'customer_name' => 'بشير العزكي',
            'customer_phone' => '967770000000',
            'customer_email' => 'customer@example.com',
            'shipping_address' => 'شارع حدة، صنعاء',
            'shipping_city' => 'صنعاء',
            'customer_notes' => 'يرجى الاتصال قبل التوصيل',
            'source' => 'storefront',
            'grand_total' => 1000,
        ]);
    }

    public function test_inactive_storefront_rejects_bootstrap_and_orders()
    {
        $business = Business::factory()->create([
            'storefront_slug' => 'store-inactive',
            'status' => 'Active',
            'storefront_active' => false,
        ]);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        Channel::factory()->create(['business_id' => $business->id, 'channel_name' => 'Online Store']);

        $product = Product::factory()->create([
            'business_id' => $business->id,
            'is_active' => true,
            'show_in_store' => true,
        ]);
        $unit = Unit::factory()->create();
        $productUnit = ProductUnit::factory()->create([
            'business_id' => $business->id,
            'product_id' => $product->id,
            'unit_id' => $unit->id,
            'selling_price' => 100,
        ]);

        // Bootstrap should return 404 for inactive store
        $bootstrapResp = $this->getJson('/api/storefront/v1/store-inactive/bootstrap');
        $bootstrapResp->assertStatus(404);

        // Products should return 404 for inactive store
        $productsResp = $this->getJson('/api/storefront/v1/store-inactive/products');
        $productsResp->assertStatus(404);

        // Order submission should return 403
        $orderResp = $this->postJson('/api/storefront/v1/store-inactive/orders', [
            'idempotency_key' => 'inactive-key-1',
            'customer_name' => 'Test',
            'items' => [
                ['product_unit_id' => $productUnit->id, 'quantity' => 1],
            ],
        ]);
        $orderResp->assertStatus(403);
    }

    public function test_show_in_store_false_excludes_product_from_storefront()
    {
        $business = Business::factory()->create([
            'storefront_slug' => 'store-publish-check',
            'status' => 'Active',
            'storefront_active' => true,
        ]);

        $publicProduct = Product::factory()->create([
            'business_id' => $business->id,
            'product_name' => 'Public Product',
            'is_active' => true,
            'show_in_store' => true,
        ]);

        $internalProduct = Product::factory()->create([
            'business_id' => $business->id,
            'product_name' => 'Internal ERP Only',
            'is_active' => true,
            'show_in_store' => false,
        ]);

        $response = $this->getJson('/api/storefront/v1/store-publish-check/products');
        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.product_name', 'Public Product');

        // Direct product detail of unpublished product must return 404
        $detailResp = $this->getJson("/api/storefront/v1/store-publish-check/products/{$internalProduct->id}");
        $detailResp->assertStatus(404);
    }

    public function test_product_detail_cross_tenant_and_unpublished_protection()
    {
        $businessA = Business::factory()->create(['storefront_slug' => 'store-a', 'status' => 'Active', 'storefront_active' => true]);
        $businessB = Business::factory()->create(['storefront_slug' => 'store-b', 'status' => 'Active', 'storefront_active' => true]);

        $productB = Product::factory()->create([
            'business_id' => $businessB->id,
            'is_active' => true,
            'show_in_store' => true,
        ]);

        $inactiveProductA = Product::factory()->create([
            'business_id' => $businessA->id,
            'is_active' => false,
            'show_in_store' => true,
        ]);

        $deletedProductA = Product::factory()->create([
            'business_id' => $businessA->id,
            'is_active' => true,
            'show_in_store' => true,
        ]);
        $deletedProductA->delete();

        // 1. Cross-tenant access must return 404
        $this->getJson("/api/storefront/v1/store-a/products/{$productB->id}")->assertStatus(404);

        // 2. Inactive product must return 404
        $this->getJson("/api/storefront/v1/store-a/products/{$inactiveProductA->id}")->assertStatus(404);

        // 3. Trashed product must return 404
        $this->getJson("/api/storefront/v1/store-a/products/{$deletedProductA->id}")->assertStatus(404);
    }

    public function test_order_creation_rejects_ineligible_products_and_units()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-eligibility', 'status' => 'Active', 'storefront_active' => true]);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        Channel::factory()->create(['business_id' => $business->id, 'channel_name' => 'Online Store']);
        $unit = Unit::factory()->create(['business_id' => $business->id]);

        // 1. Unpublished product unit
        $unpubProduct = Product::factory()->create(['business_id' => $business->id, 'is_active' => true, 'show_in_store' => false]);
        $unpubUnit = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $unpubProduct->id, 'unit_id' => $unit->id, 'selling_price' => 100]);
        InventoryProjection::create(['business_id' => $business->id, 'branch_id' => $branch->id, 'product_unit_id' => $unpubUnit->id, 'quantity' => 10, 'revision' => 1]);

        $this->postJson('/api/storefront/v1/store-eligibility/orders', [
            'idempotency_key' => 'unpub-order-test',
            'items' => [['product_unit_id' => $unpubUnit->id, 'quantity' => 1]],
        ])->assertStatus(422)
            ->assertJsonPath('code', 'PRODUCT_UNIT_UNAVAILABLE');

        // 2. Inactive product unit
        $pubProduct = Product::factory()->create(['business_id' => $business->id, 'is_active' => true, 'show_in_store' => true]);
        $inactiveUnit = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $pubProduct->id, 'unit_id' => $unit->id, 'is_active' => false, 'selling_price' => 100]);
        InventoryProjection::create(['business_id' => $business->id, 'branch_id' => $branch->id, 'product_unit_id' => $inactiveUnit->id, 'quantity' => 10, 'revision' => 1]);

        $this->postJson('/api/storefront/v1/store-eligibility/orders', [
            'idempotency_key' => 'inactive-unit-test',
            'items' => [['product_unit_id' => $inactiveUnit->id, 'quantity' => 1]],
        ])->assertStatus(422)
            ->assertJsonPath('code', 'PRODUCT_UNIT_UNAVAILABLE');

        // 3. Inactive product
        $inactiveProduct = Product::factory()->create(['business_id' => $business->id, 'is_active' => false, 'show_in_store' => true]);
        $activeUnitOnInactiveProd = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $inactiveProduct->id, 'unit_id' => $unit->id, 'is_active' => true, 'selling_price' => 100]);
        InventoryProjection::create(['business_id' => $business->id, 'branch_id' => $branch->id, 'product_unit_id' => $activeUnitOnInactiveProd->id, 'quantity' => 10, 'revision' => 1]);

        $this->postJson('/api/storefront/v1/store-eligibility/orders', [
            'idempotency_key' => 'inactive-prod-test',
            'items' => [['product_unit_id' => $activeUnitOnInactiveProd->id, 'quantity' => 1]],
        ])->assertStatus(422)
            ->assertJsonPath('code', 'PRODUCT_UNIT_UNAVAILABLE');

        // 4. Soft deleted product
        $deletedProduct = Product::factory()->create(['business_id' => $business->id, 'is_active' => true, 'show_in_store' => true]);
        $unitOnDeletedProd = ProductUnit::factory()->create(['business_id' => $business->id, 'product_id' => $deletedProduct->id, 'unit_id' => $unit->id, 'is_active' => true, 'selling_price' => 100]);
        $deletedProduct->delete();
        InventoryProjection::create(['business_id' => $business->id, 'branch_id' => $branch->id, 'product_unit_id' => $unitOnDeletedProd->id, 'quantity' => 10, 'revision' => 1]);

        $this->postJson('/api/storefront/v1/store-eligibility/orders', [
            'idempotency_key' => 'deleted-prod-test',
            'items' => [['product_unit_id' => $unitOnDeletedProd->id, 'quantity' => 1]],
        ])->assertStatus(422)
            ->assertJsonPath('code', 'PRODUCT_UNIT_UNAVAILABLE');

        // 5. Mismatched product_id in payload
        $unit2 = Unit::factory()->create(['business_id' => $business->id]);
        $validUnit = ProductUnit::factory()->create([
            'business_id' => $business->id,
            'product_id' => $pubProduct->id,
            'unit_id' => $unit2->id,
            'is_base_unit' => false,
            'is_active' => true,
            'selling_price' => 100,
        ]);
        InventoryProjection::create(['business_id' => $business->id, 'branch_id' => $branch->id, 'product_unit_id' => $validUnit->id, 'quantity' => 10, 'revision' => 1]);

        $this->postJson('/api/storefront/v1/store-eligibility/orders', [
            'idempotency_key' => 'mismatch-test',
            'items' => [
                [
                    'product_unit_id' => $validUnit->id,
                    'product_id' => (string) Str::uuid(),
                    'quantity' => 1,
                ],
            ],
        ])->assertStatus(422);
    }

    public function test_order_creation_uses_server_side_price_and_snapshots_history()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-price-check', 'status' => 'Active', 'storefront_active' => true]);
        $branch = Branch::factory()->create(['business_id' => $business->id, 'is_online_branch' => true]);
        Channel::factory()->create(['business_id' => $business->id, 'channel_name' => 'Online Store']);
        $unit = Unit::factory()->create(['business_id' => $business->id]);

        $product = Product::factory()->create(['business_id' => $business->id, 'is_active' => true, 'show_in_store' => true]);
        $productUnit = ProductUnit::factory()->create([
            'business_id' => $business->id,
            'product_id' => $product->id,
            'unit_id' => $unit->id,
            'is_active' => true,
            'selling_price' => 250.00,
        ]);
        InventoryProjection::create(['business_id' => $business->id, 'branch_id' => $branch->id, 'product_unit_id' => $productUnit->id, 'quantity' => 10, 'revision' => 1]);

        // Attempting to send manipulated client price of 10.00
        $response = $this->postJson('/api/storefront/v1/store-price-check/orders', [
            'idempotency_key' => 'price-tamper-check',
            'customer_name' => 'Honest Buyer',
            'items' => [
                [
                    'product_unit_id' => $productUnit->id,
                    'price' => 10.00,
                    'selling_price' => 10.00,
                    'quantity' => 2,
                ],
            ],
        ]);

        $response->assertStatus(201);

        // Grand total must use server selling_price (250 * 2 = 500)
        $this->assertDatabaseHas('orders', [
            'business_id' => $business->id,
            'grand_total' => 500.00,
            'sub_total' => 500.00,
        ]);

        // Order item must snapshot historical price 250.00
        $this->assertDatabaseHas('order_items', [
            'product_unit_id' => $productUnit->id,
            'quantity' => 2,
            'unit_price' => 250.00,
            'line_total' => 500.00,
        ]);
    }

    public function test_categories_list_can_filter_only_with_published_products()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-cat-filter', 'status' => 'Active', 'storefront_active' => true]);

        $catWithPublished = Category::factory()->create(['business_id' => $business->id, 'category_name' => 'Published Cat', 'is_active' => true]);
        $catWithUnpublished = Category::factory()->create(['business_id' => $business->id, 'category_name' => 'Unpublished Cat', 'is_active' => true]);
        $catWithInactive = Category::factory()->create(['business_id' => $business->id, 'category_name' => 'Inactive Prod Cat', 'is_active' => true]);

        Product::factory()->create(['business_id' => $business->id, 'category_id' => $catWithPublished->id, 'is_active' => true, 'show_in_store' => true]);
        Product::factory()->create(['business_id' => $business->id, 'category_id' => $catWithUnpublished->id, 'is_active' => true, 'show_in_store' => false]);
        Product::factory()->create(['business_id' => $business->id, 'category_id' => $catWithInactive->id, 'is_active' => false, 'show_in_store' => true]);

        // When only_with_products is requested, only Category with published active product is returned
        $response = $this->getJson('/api/storefront/v1/store-cat-filter/categories?only_with_products=1');
        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.category_name', 'Published Cat');
    }

    public function test_closed_storefront_blocks_catalog_and_orders_then_displays_latest_synced_on_reopen()
    {
        $business = Business::factory()->create([
            'storefront_slug' => 'store-reopen',
            'status' => 'Active',
            'storefront_active' => false,
        ]);

        $product = Product::factory()->create([
            'business_id' => $business->id,
            'product_name' => 'Product While Closed',
            'is_active' => true,
            'show_in_store' => true,
        ]);

        // While storefront is closed, products list returns 404
        $this->getJson('/api/storefront/v1/store-reopen/products')->assertStatus(404);

        // Reopen store
        $business->update(['storefront_active' => true]);

        // When reopened, latest synced catalog is available
        $response = $this->getJson('/api/storefront/v1/store-reopen/products');
        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.product_name', 'Product While Closed');
    }

    public function test_image_sanitization_masks_local_device_paths()
    {
        $business = Business::factory()->create(['storefront_slug' => 'store-images', 'status' => 'Active', 'storefront_active' => true]);
        $product = Product::factory()->create(['business_id' => $business->id, 'is_active' => true, 'show_in_store' => true]);

        // 1. Android local device path
        ProductImage::create([
            'id' => (string) Str::uuid(),
            'product_id' => $product->id,
            'image_path' => '/data/user/0/com.smartmerchant.erp/app_flutter/img1.jpg',
            'is_primary' => true,
            'revision' => 1,
        ]);

        // 2. Valid web URL
        ProductImage::create([
            'id' => (string) Str::uuid(),
            'product_id' => $product->id,
            'image_path' => 'https://cdn.example.com/products/p1.jpg',
            'is_primary' => false,
            'revision' => 1,
        ]);

        $response = $this->getJson("/api/storefront/v1/store-images/products/{$product->id}");
        $response->assertStatus(200);

        // Primary image had a device path, so sanitized primary_image is null
        $response->assertJsonPath('data.primary_image', null);

        // First image (primary) has null image_path and has_fallback true
        $response->assertJsonPath('data.images.0.image_path', null);
        $response->assertJsonPath('data.images.0.has_fallback', true);

        // Second image has public web url and has_fallback false
        $response->assertJsonPath('data.images.1.image_path', 'https://cdn.example.com/products/p1.jpg');
        $response->assertJsonPath('data.images.1.has_fallback', false);
    }
}
