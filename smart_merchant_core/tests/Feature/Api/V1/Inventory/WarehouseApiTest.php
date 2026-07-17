<?php

namespace Tests\Feature\Api\V1\Inventory;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\Warehouse;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WarehouseApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Business $business;
    private Branch $branch;
    private string $baseUrl = '/api/v1/inventory/warehouses';

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->business = Business::factory()->create();
        $this->branch = Branch::factory()->create(['business_id' => $this->business->id]);
        $this->user = User::factory()->create(['business_id' => $this->business->id]);
    }

    public function test_can_list_warehouses()
    {
        Warehouse::factory()->count(3)->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->getJson($this->baseUrl);

        $response->assertStatus(200)
                 ->assertJsonCount(3, 'data');
    }

    public function test_can_create_warehouse()
    {
        $payload = [
            'branch_id' => $this->branch->id,
            'warehouse_name' => 'Main Warehouse',
            'warehouse_code' => 'WH-001',
            'is_default' => true
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl, $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('warehouse_code', 'WH-001');

        $this->assertDatabaseHas('warehouses', [
            'business_id' => $this->business->id,
            'warehouse_code' => 'WH-001'
        ]);
    }

    public function test_cannot_create_duplicate_code_for_same_business()
    {
        Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'warehouse_code' => 'WH-001'
        ]);

        $payload = [
            'branch_id' => $this->branch->id,
            'warehouse_name' => 'Second Warehouse',
            'warehouse_code' => 'WH-001'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl, $payload);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['warehouse_code']);
    }

    public function test_can_create_duplicate_code_for_different_business()
    {
        $otherBusiness = Business::factory()->create();
        Warehouse::factory()->create([
            'business_id' => $otherBusiness->id,
            'warehouse_code' => 'WH-001'
        ]);

        $payload = [
            'branch_id' => $this->branch->id,
            'warehouse_name' => 'My Warehouse',
            'warehouse_code' => 'WH-001'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl, $payload);

        $response->assertStatus(201);
    }

    public function test_can_update_warehouse()
    {
        $warehouse = Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'warehouse_name' => 'Old Name'
        ]);

        $payload = [
            'warehouse_name' => 'New Name'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->putJson($this->baseUrl . '/' . $warehouse->id, $payload);

        $response->assertStatus(200)
                 ->assertJsonPath('warehouse_name', 'New Name');
    }

    public function test_cannot_update_cross_tenant_warehouse()
    {
        $otherBusiness = Business::factory()->create();
        $warehouse = Warehouse::factory()->create([
            'business_id' => $otherBusiness->id,
        ]);

        $payload = [
            'warehouse_name' => 'Hacked Name'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->putJson($this->baseUrl . '/' . $warehouse->id, $payload);

        $response->assertStatus(403);
    }

    public function test_can_soft_delete_warehouse()
    {
        // Need to create another active one so this isn't the last active
        Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'is_active' => true,
            'is_default' => false
        ]);

        $warehouse = Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'is_default' => false
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson($this->baseUrl . '/' . $warehouse->id);

        $response->assertStatus(204);

        $this->assertSoftDeleted('warehouses', ['id' => $warehouse->id]);
    }

    public function test_cannot_delete_last_active_warehouse()
    {
        $warehouse = Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'is_default' => false,
            'is_active' => true
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson($this->baseUrl . '/' . $warehouse->id);

        // InventoryDomainException thrown -> 400
        $response->assertStatus(400);
        $this->assertDatabaseHas('warehouses', ['id' => $warehouse->id, 'deleted_at' => null]);
    }

    public function test_can_activate_and_deactivate()
    {
        Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'is_active' => true,
            'is_default' => false
        ]);

        $warehouse = Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'is_active' => false,
            'is_default' => false
        ]);

        $res1 = $this->actingAs($this->user, 'sanctum')->patchJson($this->baseUrl . '/' . $warehouse->id . '/activate');
        $res1->assertStatus(200)->assertJsonPath('is_active', true);

        $res2 = $this->actingAs($this->user, 'sanctum')->patchJson($this->baseUrl . '/' . $warehouse->id . '/deactivate');
        $res2->assertStatus(200)->assertJsonPath('is_active', false);
    }
}
