<?php

namespace Tests\Feature\Purchasing;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Business;
use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Actions\PurchaseInvoice\CreatePurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\UpdatePurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\DeletePurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\GetPurchaseInvoiceAction;
use App\Domains\Purchasing\Actions\PurchaseInvoice\ListPurchaseInvoicesAction;
use Mockery;
use Illuminate\Support\Collection;

class PurchaseInvoicePresentationTest extends TestCase
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

    public function test_can_list_purchase_invoices()
    {
        $mock = Mockery::mock(ListPurchaseInvoicesAction::class);
        $mock->shouldReceive('execute')
             ->once()
             ->with($this->business->id)
             ->andReturn(new Collection([
                 new PurchaseInvoice(['id' => '123', 'business_id' => $this->business->id, 'invoice_number' => 'INV-001'])
             ]));
             
        $this->app->instance(ListPurchaseInvoicesAction::class, $mock);

        $response = $this->actingAs($this->user, 'sanctum')->getJson('/api/v1/purchase-invoices');

        $response->assertStatus(200)
                 ->assertJsonPath('data.0.invoice_number', 'INV-001');
    }

    public function test_can_create_purchase_invoice()
    {
        $payload = [
            'branch_id' => '00000000-0000-0000-0000-000000000001',
            'supplier_id' => '00000000-0000-0000-0000-000000000002',
            'warehouse_id' => '00000000-0000-0000-0000-000000000003',
            'invoice_number' => 'INV-123',
            'currency_id' => '00000000-0000-0000-0000-000000000004',
            'items' => [
                [
                    'product_unit_id' => '00000000-0000-0000-0000-000000000005',
                    'warehouse_id' => '00000000-0000-0000-0000-000000000003',
                    'quantity' => 10,
                    'unit_price' => 100
                ]
            ]
        ];

        $mock = Mockery::mock(CreatePurchaseInvoiceAction::class);
        $mock->shouldReceive('execute')
             ->once()
             ->andReturn(new PurchaseInvoice(['id' => 'uuid-123', 'invoice_number' => 'INV-123']));
             
        $this->app->instance(CreatePurchaseInvoiceAction::class, $mock);

        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/purchase-invoices', $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('data.invoice_number', 'INV-123');
    }

    public function test_cannot_create_with_invalid_data()
    {
        $payload = [
            'invoice_number' => 'INV-123', // Missing items, branch_id, etc.
        ];

        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/purchase-invoices', $payload);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['branch_id', 'supplier_id', 'warehouse_id', 'currency_id', 'items']);
    }

    public function test_can_show_purchase_invoice()
    {
        $invoice = new PurchaseInvoice([
            'id' => 'uuid-123',
            'business_id' => $this->business->id,
            'invoice_number' => 'INV-001'
        ]);

        $mock = Mockery::mock(GetPurchaseInvoiceAction::class);
        $mock->shouldReceive('execute')
             ->once()
             ->with($this->business->id, 'uuid-123')
             ->andReturn($invoice);
             
        $this->app->instance(GetPurchaseInvoiceAction::class, $mock);

        $response = $this->actingAs($this->user, 'sanctum')->getJson('/api/v1/purchase-invoices/uuid-123');

        $response->assertStatus(200)
                 ->assertJsonPath('data.invoice_number', 'INV-001');
    }

    public function test_cannot_show_unauthorized_invoice()
    {
        $invoice = new PurchaseInvoice([
            'id' => 'uuid-123',
            'business_id' => 'other-business',
            'invoice_number' => 'INV-001'
        ]);

        $mock = Mockery::mock(GetPurchaseInvoiceAction::class);
        $mock->shouldReceive('execute')
             ->once()
             ->with($this->business->id, 'uuid-123')
             ->andReturn($invoice);
             
        $this->app->instance(GetPurchaseInvoiceAction::class, $mock);

        $response = $this->actingAs($this->user, 'sanctum')->getJson('/api/v1/purchase-invoices/uuid-123');

        $response->assertStatus(403);
    }

    public function test_can_update_draft_invoice()
    {
        $invoice = new PurchaseInvoice([
            'id' => 'uuid-123',
            'business_id' => $this->business->id,
            'status' => 'Draft'
        ]);

        $getMock = Mockery::mock(GetPurchaseInvoiceAction::class);
        $getMock->shouldReceive('execute')->once()->andReturn($invoice);
        $this->app->instance(GetPurchaseInvoiceAction::class, $getMock);

        $updateMock = Mockery::mock(UpdatePurchaseInvoiceAction::class);
        $updateMock->shouldReceive('execute')->once()->andReturn($invoice);
        $this->app->instance(UpdatePurchaseInvoiceAction::class, $updateMock);

        $payload = [
            'invoice_number' => 'INV-NEW'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->putJson('/api/v1/purchase-invoices/uuid-123', $payload);

        $response->assertStatus(200);
    }

    public function test_cannot_update_posted_invoice()
    {
        $invoice = new PurchaseInvoice([
            'id' => 'uuid-123',
            'business_id' => $this->business->id,
            'status' => 'Posted'
        ]);

        $getMock = Mockery::mock(GetPurchaseInvoiceAction::class);
        $getMock->shouldReceive('execute')->once()->andReturn($invoice);
        $this->app->instance(GetPurchaseInvoiceAction::class, $getMock);

        $payload = [
            'invoice_number' => 'INV-NEW'
        ];

        $response = $this->actingAs($this->user, 'sanctum')->putJson('/api/v1/purchase-invoices/uuid-123', $payload);

        $response->assertStatus(403);
    }

    public function test_can_delete_draft_invoice()
    {
        $invoice = new PurchaseInvoice([
            'id' => 'uuid-123',
            'business_id' => $this->business->id,
            'status' => 'Draft'
        ]);

        $getMock = Mockery::mock(GetPurchaseInvoiceAction::class);
        $getMock->shouldReceive('execute')->once()->andReturn($invoice);
        $this->app->instance(GetPurchaseInvoiceAction::class, $getMock);

        $delMock = Mockery::mock(DeletePurchaseInvoiceAction::class);
        $delMock->shouldReceive('execute')->once()->andReturn(true);
        $this->app->instance(DeletePurchaseInvoiceAction::class, $delMock);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson('/api/v1/purchase-invoices/uuid-123');

        $response->assertStatus(204);
    }
}
