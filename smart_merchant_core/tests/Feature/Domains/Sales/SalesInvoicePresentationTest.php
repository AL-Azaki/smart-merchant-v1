<?php

namespace Tests\Feature\Domains\Sales;

use Tests\TestCase;
use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Business;
use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Actions\SalesInvoice\CreateSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\UpdateSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\DeleteSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\GetSalesInvoiceAction;
use App\Domains\Sales\Actions\SalesInvoice\ListSalesInvoicesAction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Illuminate\Support\Collection;

class SalesInvoicePresentationTest extends TestCase
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

    public function test_can_list_sales_invoices()
    {
        $mockAction = Mockery::mock(ListSalesInvoicesAction::class);
        $mockAction->shouldReceive('execute')
            ->once()
            ->with($this->business->id)
            ->andReturn(new Collection([]));

        $this->app->instance(ListSalesInvoicesAction::class, $mockAction);

        $response = $this->actingAs($this->user)->getJson('/api/v1/sales-invoices');

        $response->assertStatus(200)
            ->assertJsonStructure(['data', 'meta']);
    }

    public function test_can_create_sales_invoice()
    {
        $invoice = SalesInvoice::factory()->make(['id' => 'test-uuid']);
        
        $mockAction = Mockery::mock(CreateSalesInvoiceAction::class);
        $mockAction->shouldReceive('execute')
            ->once()
            ->andReturn($invoice);

        $this->app->instance(CreateSalesInvoiceAction::class, $mockAction);

        $payload = [
            'branch_id' => 'branch-uuid',
            'invoice_number' => 'INV-001',
            'invoice_date' => '2026-07-14',
            'currency_id' => 'curr-uuid',
            'exchange_rate' => 1,
            'sub_total' => 100,
            'discount_total' => 0,
            'tax_total' => 0,
            'grand_total' => 100,
            'base_sub_total' => 100,
            'base_discount_total' => 0,
            'base_tax_total' => 0,
            'base_grand_total' => 100,
            'payment_status' => 'Unpaid',
            'items' => [
                [
                    'product_unit_id' => 'prod-uuid',
                    'warehouse_id' => 'wh-uuid',
                    'quantity' => 1,
                    'unit_price' => 100,
                    'discount' => 0,
                    'tax' => 0,
                    'line_total' => 100,
                    'base_line_total' => 100,
                ]
            ]
        ];

        $response = $this->actingAs($this->user)->postJson('/api/v1/sales-invoices', $payload);

        $response->assertStatus(201);
    }

    public function test_can_show_sales_invoice()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'id' => 'test-uuid'
        ]);

        $mockAction = Mockery::mock(GetSalesInvoiceAction::class);
        $mockAction->shouldReceive('execute')
            ->once()
            ->with($this->business->id, 'test-uuid')
            ->andReturn($invoice);

        $this->app->instance(GetSalesInvoiceAction::class, $mockAction);

        $response = $this->actingAs($this->user)->getJson('/api/v1/sales-invoices/test-uuid');

        $response->assertStatus(200);
    }

    public function test_can_update_draft_sales_invoice()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Draft',
            'id' => 'test-uuid'
        ]);

        $mockGet = Mockery::mock(GetSalesInvoiceAction::class);
        $mockGet->shouldReceive('execute')
            ->once()
            ->with($this->business->id, 'test-uuid')
            ->andReturn($invoice);

        $mockUpdate = Mockery::mock(UpdateSalesInvoiceAction::class);
        $mockUpdate->shouldReceive('execute')
            ->once()
            ->andReturn($invoice);

        $this->app->instance(GetSalesInvoiceAction::class, $mockGet);
        $this->app->instance(UpdateSalesInvoiceAction::class, $mockUpdate);

        $payload = [
            'notes' => 'Updated notes'
        ];

        $response = $this->actingAs($this->user)->putJson('/api/v1/sales-invoices/test-uuid', $payload);

        $response->assertStatus(200);
    }

    public function test_can_delete_draft_sales_invoice()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Draft',
            'id' => 'test-uuid'
        ]);

        $mockGet = Mockery::mock(GetSalesInvoiceAction::class);
        $mockGet->shouldReceive('execute')
            ->once()
            ->with($this->business->id, 'test-uuid')
            ->andReturn($invoice);

        $mockDelete = Mockery::mock(DeleteSalesInvoiceAction::class);
        $mockDelete->shouldReceive('execute')
            ->once()
            ->with($invoice)
            ->andReturn(true);

        $this->app->instance(GetSalesInvoiceAction::class, $mockGet);
        $this->app->instance(DeleteSalesInvoiceAction::class, $mockDelete);

        $response = $this->actingAs($this->user)->deleteJson('/api/v1/sales-invoices/test-uuid');

        $response->assertStatus(204);
    }
}
