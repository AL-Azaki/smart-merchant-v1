<?php

namespace Tests\Feature\Domains\Inventory;

use Tests\TestCase;
use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Business;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Actions\InventoryTransaction\CreateInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\UpdateInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\DeleteInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\GetInventoryTransactionAction;
use App\Domains\Inventory\Actions\InventoryTransaction\ListInventoryTransactionsAction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Illuminate\Support\Collection;

class InventoryTransactionPresentationTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Business $business;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->business = Business::factory()->create();
        $this->user = User::factory()->create(['business_id' => $this->business->id]);
    }

    public function test_can_list_inventory_transactions()
    {
        $mockAction = Mockery::mock(ListInventoryTransactionsAction::class);
        $mockAction->shouldReceive('execute')
            ->once()
            ->with($this->business->id)
            ->andReturn(new Collection([]));

        $this->app->instance(ListInventoryTransactionsAction::class, $mockAction);

        $response = $this->actingAs($this->user)->getJson('/api/v1/inventory-transactions');

        $response->assertStatus(200)
            ->assertJsonStructure(['data', 'meta']);
    }

    public function test_can_create_inventory_transaction()
    {
        $transaction = InventoryTransaction::factory()->make(['id' => 'test-uuid']);
        
        $mockAction = Mockery::mock(CreateInventoryTransactionAction::class);
        $mockAction->shouldReceive('execute')
            ->once()
            ->andReturn($transaction);

        $this->app->instance(CreateInventoryTransactionAction::class, $mockAction);

        $payload = [
            'warehouse_id' => 'wh-uuid',
            'transaction_type' => 'Receipt',
            'lines' => [
                [
                    'product_unit_id' => 'prod-uuid',
                    'line_number' => 1,
                    'quantity' => 10,
                    'unit_cost' => 100,
                ]
            ]
        ];

        $response = $this->actingAs($this->user)->postJson('/api/v1/inventory-transactions', $payload);

        $response->assertStatus(201);
    }

    public function test_can_show_inventory_transaction()
    {
        $transaction = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'id' => 'test-uuid'
        ]);

        $mockAction = Mockery::mock(GetInventoryTransactionAction::class);
        $mockAction->shouldReceive('execute')
            ->once()
            ->with($this->business->id, 'test-uuid')
            ->andReturn($transaction);

        $this->app->instance(GetInventoryTransactionAction::class, $mockAction);

        $response = $this->actingAs($this->user)->getJson('/api/v1/inventory-transactions/test-uuid');

        $response->assertStatus(200);
    }

    public function test_can_update_draft_inventory_transaction()
    {
        $transaction = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Draft',
            'id' => 'test-uuid'
        ]);

        $mockGet = Mockery::mock(GetInventoryTransactionAction::class);
        $mockGet->shouldReceive('execute')
            ->once()
            ->with($this->business->id, 'test-uuid')
            ->andReturn($transaction);

        $mockUpdate = Mockery::mock(UpdateInventoryTransactionAction::class);
        $mockUpdate->shouldReceive('execute')
            ->once()
            ->andReturn($transaction);

        $this->app->instance(GetInventoryTransactionAction::class, $mockGet);
        $this->app->instance(UpdateInventoryTransactionAction::class, $mockUpdate);

        $payload = [
            'notes' => 'Updated notes'
        ];

        $response = $this->actingAs($this->user)->putJson('/api/v1/inventory-transactions/test-uuid', $payload);

        $response->assertStatus(200);
    }

    public function test_can_delete_draft_inventory_transaction()
    {
        $transaction = InventoryTransaction::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Draft',
            'id' => 'test-uuid'
        ]);

        $mockGet = Mockery::mock(GetInventoryTransactionAction::class);
        $mockGet->shouldReceive('execute')
            ->once()
            ->with($this->business->id, 'test-uuid')
            ->andReturn($transaction);

        $mockDelete = Mockery::mock(DeleteInventoryTransactionAction::class);
        $mockDelete->shouldReceive('execute')
            ->once()
            ->with($transaction)
            ->andReturn(true);

        $this->app->instance(GetInventoryTransactionAction::class, $mockGet);
        $this->app->instance(DeleteInventoryTransactionAction::class, $mockDelete);

        $response = $this->actingAs($this->user)->deleteJson('/api/v1/inventory-transactions/test-uuid');

        $response->assertStatus(204);
    }
}
