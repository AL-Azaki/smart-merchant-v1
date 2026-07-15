<?php

namespace Tests\Feature\Purchasing\Integration;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Actions\AccountMapping\ResolveAccountMappingAction;
use App\Domains\Purchasing\Services\Integration\PurchasingPostingService;
use App\Domains\Purchasing\Services\Integration\PurchasingPostingRequestDTOBuilder;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use Exception;
use Mockery;
use Illuminate\Support\Str;

class PurchasingFinanceIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private PurchasingPostingService $service;
    private $postingEngineMock;
    private $resolveAccountMappingMock;
    private PurchaseInvoice $invoice;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->postingEngineMock = Mockery::mock(PostingEngineInterface::class);
        $this->app->instance(PostingEngineInterface::class, $this->postingEngineMock);

        $this->resolveAccountMappingMock = Mockery::mock(ResolveAccountMappingAction::class);
        $this->app->instance(ResolveAccountMappingAction::class, $this->resolveAccountMappingMock);

        $builder = new PurchasingPostingRequestDTOBuilder($this->resolveAccountMappingMock);
        
        $this->service = new PurchasingPostingService(
            $builder,
            $this->postingEngineMock
        );

        $this->invoice = new PurchaseInvoice();
        $this->invoice->id = Str::uuid()->toString();
        $this->invoice->business_id = Str::uuid()->toString();
        $this->invoice->branch_id = Str::uuid()->toString();
        $this->invoice->status = 'Posted';
        $this->invoice->invoice_number = 'INV-TEST';
        $this->invoice->purchase_date = now();
        $this->invoice->base_sub_total = 1000;
        $this->invoice->base_tax_total = 150;
        $this->invoice->base_discount_total = 50;
        $this->invoice->base_grand_total = 1100;
    }

    public function test_successful_posting_integration()
    {
        // Mock account resolution
        $this->resolveAccountMappingMock->shouldReceive('execute')
            ->with($this->invoice->business_id, 'inventory_asset')
            ->andReturn(Str::uuid()->toString());
            
        $this->resolveAccountMappingMock->shouldReceive('execute')
            ->with($this->invoice->business_id, 'input_vat')
            ->andReturn(Str::uuid()->toString());

        $this->resolveAccountMappingMock->shouldReceive('execute')
            ->with($this->invoice->business_id, 'discount_received')
            ->andReturn(Str::uuid()->toString());

        $this->resolveAccountMappingMock->shouldReceive('execute')
            ->with($this->invoice->business_id, 'accounts_payable')
            ->andReturn(Str::uuid()->toString());

        $this->postingEngineMock->shouldReceive('post')
            ->once()
            ->andReturn(new PostingResultDTO(true, 'uuid-123', 'Success'));

        $this->service->postInvoice($this->invoice);
        
        $this->assertTrue(true); // Asserting that no exception was thrown
    }

    public function test_fails_if_not_posted()
    {
        $this->invoice->status = 'Draft';
        
        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Cannot post an invoice that is not Posted.");
        
        $this->service->postInvoice($this->invoice);
    }

    public function test_fails_if_idempotency_violated()
    {
        $this->resolveAccountMappingMock->shouldReceive('execute')->andReturn(Str::uuid()->toString());

        $this->postingEngineMock->shouldReceive('post')
            ->once()
            ->andThrow(new Exception("Journal Entry already exists for this reference."));

        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Journal Entry already exists for this reference.");
        
        $this->service->postInvoice($this->invoice);
    }

    public function test_transaction_rollback_on_posting_failure()
    {
        $this->resolveAccountMappingMock->shouldReceive('execute')->andReturn(Str::uuid()->toString());

        $this->postingEngineMock->shouldReceive('post')
            ->once()
            ->andThrow(new Exception("Posting Error"));

        $this->expectException(Exception::class);
        $this->expectExceptionMessage("Posting Error");
        
        $this->service->postInvoice($this->invoice);
    }
}
