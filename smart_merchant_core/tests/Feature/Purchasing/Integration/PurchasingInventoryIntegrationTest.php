<?php

namespace Tests\Feature\Purchasing\Integration;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Models\PurchaseInvoiceItem;
use App\Domains\Inventory\Services\InventoryStockService;
use App\Domains\Purchasing\Services\Integration\PurchasingInventoryIntegrationService;
use App\Domains\Purchasing\Services\Integration\PurchasingInventoryTransactionBuilder;
use App\Domains\Purchasing\Services\Integration\PurchasingInventoryTransactionLinesBuilder;
use Exception;
use Mockery;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PurchasingInventoryIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private PurchasingInventoryIntegrationService $service;
    private $inventoryStockServiceMock;
    private PurchaseInvoice $invoice;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->inventoryStockServiceMock = Mockery::mock(InventoryStockService::class);
        $this->app->instance(InventoryStockService::class, $this->inventoryStockServiceMock);

        $linesBuilder = new PurchasingInventoryTransactionLinesBuilder();
        $builder = new PurchasingInventoryTransactionBuilder($linesBuilder);
        
        $this->service = new PurchasingInventoryIntegrationService(
            $builder,
            $this->inventoryStockServiceMock
        );

        // We use make and set attributes to avoid relying on complex factories
        $this->invoice = new PurchaseInvoice();
        $this->invoice->id = Str::uuid()->toString();
        $this->invoice->business_id = Str::uuid()->toString();
        $this->invoice->warehouse_id = Str::uuid()->toString();
        $this->invoice->status = 'Posted';
        $this->invoice->invoice_number = 'INV-TEST';

        $item1 = new PurchaseInvoiceItem();
        $item1->business_id = $this->invoice->business_id;
        $item1->product_unit_id = Str::uuid()->toString();
        $item1->quantity = 10;
        $item1->unit_price = 50;

        $item2 = new PurchaseInvoiceItem();
        $item2->business_id = $this->invoice->business_id;
        $item2->product_unit_id = Str::uuid()->toString();
        $item2->quantity = 5;
        $item2->unit_price = 20;

        $this->invoice->setRelation('items', collect([$item1, $item2]));
    }

    public function test_successful_integration()
    {
        $this->inventoryStockServiceMock->shouldReceive('hasTransactionForReference')
            ->once()
            ->with($this->invoice->business_id, 'PurchaseInvoice', $this->invoice->id)
            ->andReturn(false);

        $this->inventoryStockServiceMock->shouldReceive('increaseStock')
            ->twice()
            ->andReturn((object)[]);

        $this->service->receiveStockForInvoice($this->invoice);
        
        $this->assertTrue(true); // Asserting that no exception was thrown
    }

    public function test_fails_if_not_posted()
    {
        $this->invoice->status = 'Draft';
        
        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Cannot receive stock for an invoice that is not Posted.");
        
        $this->service->receiveStockForInvoice($this->invoice);
    }

    public function test_fails_if_already_received()
    {
        $this->inventoryStockServiceMock->shouldReceive('hasTransactionForReference')
            ->once()
            ->andReturn(true);

        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Inventory has already been received for this invoice.");
        
        $this->service->receiveStockForInvoice($this->invoice);
    }

    public function test_transaction_rollback_on_inventory_failure()
    {
        $this->inventoryStockServiceMock->shouldReceive('hasTransactionForReference')
            ->once()
            ->andReturn(false);

        $this->inventoryStockServiceMock->shouldReceive('increaseStock')
            ->once()
            ->andThrow(new Exception("Inventory Error"));

        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Inventory Error");
        
        $this->service->receiveStockForInvoice($this->invoice);
    }
}
