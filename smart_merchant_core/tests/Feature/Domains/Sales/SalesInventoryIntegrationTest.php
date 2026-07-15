<?php

namespace Tests\Feature\Domains\Sales;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Models\SalesInvoiceItem;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Sales\Services\Integration\SalesInventoryIntegrationService;
use App\Domains\Inventory\Services\InventoryStockService;
use Exception;
use Mockery;

class SalesInventoryIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private Business $business;
    private Branch $branch;
    private Warehouse $warehouse;
    private ProductUnit $productUnit;
    private SalesInventoryIntegrationService $integrationService;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->business = Business::factory()->create();
        $this->branch = Branch::factory()->create(['business_id' => $this->business->id]);
        $this->warehouse = Warehouse::factory()->create(['business_id' => $this->business->id, 'branch_id' => $this->branch->id]);
        $this->productUnit = ProductUnit::factory()->create(['business_id' => $this->business->id]);
        
        $this->integrationService = app(SalesInventoryIntegrationService::class);
    }

    public function test_can_dispatch_stock_for_posted_invoice()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Posted'
        ]);

        SalesInvoiceItem::factory()->create([
            'business_id' => $this->business->id,
            'sales_invoice_id' => $invoice->id,
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 5
        ]);

        $mockStockService = Mockery::mock(InventoryStockService::class);
        $mockStockService->shouldReceive('hasTransactionForReference')
            ->once()
            ->andReturn(false);
            
        $mockStockService->shouldReceive('decreaseStockBulk')
            ->once()
            ->andReturn(Mockery::mock(\App\Domains\Inventory\Models\InventoryTransaction::class));

        $this->app->instance(InventoryStockService::class, $mockStockService);
        
        $service = app(SalesInventoryIntegrationService::class);
        $service->dispatchStockForInvoice($invoice);
        
        // Assertions are handled by Mockery
        $this->assertTrue(true);
    }

    public function test_cannot_dispatch_draft_invoice()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Draft'
        ]);

        SalesInvoiceItem::factory()->create([
            'business_id' => $this->business->id,
            'sales_invoice_id' => $invoice->id,
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 5
        ]);

        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Cannot dispatch stock for an invoice that is not Posted.");

        $this->integrationService->dispatchStockForInvoice($invoice);
    }

    public function test_cannot_dispatch_twice()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Posted'
        ]);

        SalesInvoiceItem::factory()->create([
            'business_id' => $this->business->id,
            'sales_invoice_id' => $invoice->id,
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 5
        ]);

        $mockStockService = Mockery::mock(InventoryStockService::class);
        $mockStockService->shouldReceive('hasTransactionForReference')
            ->once()
            ->andReturn(true);

        $this->app->instance(InventoryStockService::class, $mockStockService);
        
        $service = app(SalesInventoryIntegrationService::class);
        
        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Inventory has already been dispatched for this invoice.");

        $service->dispatchStockForInvoice($invoice);
    }

    public function test_rolls_back_on_inventory_failure()
    {
        $invoice = SalesInvoice::factory()->create([
            'business_id' => $this->business->id,
            'status' => 'Posted'
        ]);

        SalesInvoiceItem::factory()->create([
            'business_id' => $this->business->id,
            'sales_invoice_id' => $invoice->id,
            'warehouse_id' => $this->warehouse->id,
            'product_unit_id' => $this->productUnit->id,
            'quantity' => 5
        ]);

        $mockStockService = Mockery::mock(InventoryStockService::class);
        $mockStockService->shouldReceive('hasTransactionForReference')
            ->once()
            ->andReturn(false);
            
        $mockStockService->shouldReceive('decreaseStockBulk')
            ->once()
            ->andThrow(new Exception("Insufficient stock"));

        $this->app->instance(InventoryStockService::class, $mockStockService);
        
        $service = app(SalesInventoryIntegrationService::class);
        
        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Insufficient stock");

        $service->dispatchStockForInvoice($invoice);
    }
}
