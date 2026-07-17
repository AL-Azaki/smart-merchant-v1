<?php

namespace Tests\Feature\Api\V1\Inventory;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Inventory\Models\Inventory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InventoryApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Business $business;
    private Warehouse $warehouse;
    private ProductUnit $productUnit;
    private string $baseUrl = '/api/v1/inventory/inventories';

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->business = Business::factory()->create();
        $this->user = User::factory()->create(['business_id' => $this->business->id]);
        $this->warehouse = Warehouse::factory()->create(['business_id' => $this->business->id]);
        $this->productUnit = ProductUnit::factory()->create(['business_id' => $this->business->id]);
    }

    public function test_can_list_inventory()
    {
        Inventory::factory()->count(2)->create([
            'business_id' => $this->business->id,
            'warehouse_id' => $this->warehouse->id
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->getJson($this->baseUrl);

        $response->assertStatus(200)
                 ->assertJsonCount(2, 'data');
    }

    public function test_can_create_inventory()
    {
        $payload = [
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id,
            'alert_quantity' => 10.0
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl, $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('quantity', 0)
                 ->assertJsonPath('average_cost', 0)
                 ->assertJsonPath('alert_quantity', 10);

        $this->assertDatabaseHas('inventories', [
            'business_id' => $this->business->id,
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id
        ]);
    }

    public function test_cannot_create_duplicate_inventory_record()
    {
        Inventory::factory()->create([
            'business_id' => $this->business->id,
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id
        ]);

        $payload = [
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl, $payload);

        $response->assertStatus(400); // Domain Exception
    }

    public function test_can_update_alert_quantity_only()
    {
        $inventory = Inventory::factory()->create([
            'business_id' => $this->business->id,
            'warehouse_id' => $this->warehouse->id,
            'alert_quantity' => 5
        ]);

        $payload = [
            'alert_quantity' => 20
        ];

        $response = $this->actingAs($this->user, 'sanctum')->putJson($this->baseUrl . '/' . $inventory->id, $payload);

        $response->assertStatus(200)
                 ->assertJsonPath('alert_quantity', 20);
    }

    public function test_cannot_update_cross_tenant_inventory()
    {
        $otherBusiness = Business::factory()->create();
        $inventory = Inventory::factory()->create([
            'business_id' => $otherBusiness->id,
        ]);

        $payload = [
            'alert_quantity' => 50
        ];

        $response = $this->actingAs($this->user, 'sanctum')->putJson($this->baseUrl . '/' . $inventory->id, $payload);

        $response->assertStatus(403);
    }

    public function test_can_soft_delete_inventory_with_zero_balance()
    {
        $inventory = Inventory::factory()->create([
            'business_id' => $this->business->id,
            'quantity' => 0
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson($this->baseUrl . '/' . $inventory->id);

        $response->assertStatus(204);

        $this->assertSoftDeleted('inventories', ['id' => $inventory->id]);
    }

    public function test_cannot_delete_inventory_with_positive_balance()
    {
        $inventory = Inventory::factory()->create([
            'business_id' => $this->business->id,
            'quantity' => 10
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson($this->baseUrl . '/' . $inventory->id);

        // Domain Exception -> 400
        $response->assertStatus(400);
        $this->assertDatabaseHas('inventories', ['id' => $inventory->id, 'deleted_at' => null]);
    }
}
