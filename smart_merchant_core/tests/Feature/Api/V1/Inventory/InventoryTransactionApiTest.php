<?php

namespace Tests\Feature\Api\V1\Inventory;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\InventoryTransactionLine;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InventoryTransactionApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Business $business;
    private Branch $branch;
    private Warehouse $warehouse;
    private ProductUnit $productUnit;
    private string $baseUrl = '/api/v1/inventory/inventory-transactions';

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->business = Business::factory()->create();
        $this->user = User::factory()->create(['business_id' => $this->business->id]);
        $this->branch = Branch::factory()->create(['business_id' => $this->business->id]);
        $this->warehouse = Warehouse::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id
        ]);
        $this->productUnit = ProductUnit::factory()->create(['business_id' => $this->business->id]);
    }

    public function test_can_create_draft_transaction()
    {
        $payload = [
            'branch_id' => $this->branch->id,
            'warehouse_id' => $this->warehouse->id,
            'transaction_type' => 'Opening Balance',
            'movement_direction' => 'IN'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl, $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('status', 'Draft')
                 ->assertJsonPath('movement_direction', 'IN');
    }

    public function test_can_add_line_to_draft()
    {
        $tx = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'warehouse_id' => $this->warehouse->id,
            'status' => 'Draft',
            'created_by' => $this->user->id
        ]);

        $payload = [
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 15,
            'unit_cost' => 10.5
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl . '/' . $tx->id . '/lines', $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('quantity', 15)
                 ->assertJsonPath('unit_cost', 10.5);
    }

    public function test_cannot_add_line_to_posted_transaction()
    {
        $tx = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'warehouse_id' => $this->warehouse->id,
            'status' => 'Posted',
            'created_by' => $this->user->id
        ]);

        $payload = [
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 15
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson($this->baseUrl . '/' . $tx->id . '/lines', $payload);

        $response->assertStatus(400); // Domain Exception
    }

    public function test_can_post_transaction_with_lines()
    {
        $tx = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'warehouse_id' => $this->warehouse->id,
            'status' => 'Draft',
            'created_by' => $this->user->id
        ]);

        InventoryTransactionLine::factory()->create([
            'business_id' => $this->business->id,
            'inventory_transaction_id' => $tx->id,
            'product_unit_id' => $this->productUnit->id
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->patchJson($this->baseUrl . '/' . $tx->id . '/post');

        $response->assertStatus(200)
                 ->assertJsonPath('status', 'Posted');
    }

    public function test_cannot_post_transaction_without_lines()
    {
        $tx = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'warehouse_id' => $this->warehouse->id,
            'status' => 'Draft',
            'created_by' => $this->user->id
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->patchJson($this->baseUrl . '/' . $tx->id . '/post');

        $response->assertStatus(400); // Domain exception
    }

    public function test_can_reverse_posted_transaction()
    {
        $tx = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'branch_id' => $this->branch->id,
            'warehouse_id' => $this->warehouse->id,
            'status' => 'Posted',
            'created_by' => $this->user->id
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->patchJson($this->baseUrl . '/' . $tx->id . '/reverse');

        $response->assertStatus(200)
                 ->assertJsonPath('status', 'Reversed');
    }

    public function test_cross_tenant_isolation()
    {
        $otherBusiness = Business::factory()->create();
        $tx = InventoryTransaction::factory()->create([
            'business_id' => $otherBusiness->id,
            'branch_id' => Branch::factory()->create(['business_id' => $otherBusiness->id])->id,
            'warehouse_id' => Warehouse::factory()->create(['business_id' => $otherBusiness->id])->id,
            'created_by' => User::factory()->create(['business_id' => $otherBusiness->id])->id,
            'status' => 'Draft'
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson($this->baseUrl . '/' . $tx->id);

        $response->assertStatus(403);
    }
}
