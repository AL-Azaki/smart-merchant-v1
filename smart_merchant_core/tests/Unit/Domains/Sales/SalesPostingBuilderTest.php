<?php

namespace Tests\Unit\Domains\Sales;

use App\Domains\Finance\Actions\AccountMapping\ResolveAccountMappingAction;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Sales\Contracts\SalesPostingContract;
use App\Domains\Sales\Services\SalesPostingBuilder;
use PHPUnit\Framework\TestCase;

class SalesPostingBuilderTest extends TestCase
{
    private $resolveMappingMock;
    private $postingEngineMock;
    private $salesDataMock;

    protected function setUp(): void
    {
        parent::setUp();

        $this->resolveMappingMock = $this->createMock(ResolveAccountMappingAction::class);
        $this->postingEngineMock = $this->createMock(PostingEngineInterface::class);
        $this->salesDataMock = $this->createMock(SalesPostingContract::class);

        $this->salesDataMock->method('getBusinessId')->willReturn('bus-1');
        $this->salesDataMock->method('getFiscalPeriodId')->willReturn('fp-1');
        $this->salesDataMock->method('getDocumentDate')->willReturn('2026-07-14');
        $this->salesDataMock->method('getPostingDate')->willReturn('2026-07-14');
        $this->salesDataMock->method('getDocumentId')->willReturn('doc-1');
        $this->salesDataMock->method('getDocumentNumber')->willReturn('INV-1000');
        $this->salesDataMock->method('getCurrencyId')->willReturn('curr-1');
        $this->salesDataMock->method('getExchangeRate')->willReturn(1.0);
        $this->salesDataMock->method('getDescription')->willReturn('Test Invoice');
        $this->salesDataMock->method('getCreatedBy')->willReturn('user-1');
    }

    public function test_it_successfully_builds_and_posts()
    {
        $this->salesDataMock->method('getAccountsReceivableBase')->willReturn(110.0);
        $this->salesDataMock->method('getAccountsReceivableForeign')->willReturn(110.0);
        $this->salesDataMock->method('getSalesRevenueBase')->willReturn(100.0);
        $this->salesDataMock->method('getSalesRevenueForeign')->willReturn(100.0);
        $this->salesDataMock->method('getSalesTaxBase')->willReturn(10.0);
        $this->salesDataMock->method('getSalesTaxForeign')->willReturn(10.0);
        $this->salesDataMock->method('getSalesDiscountBase')->willReturn(0.0);
        
        $arAccount = new ChartOfAccount();
        $arAccount->id = 'acc-ar';

        $revenueAccount = new ChartOfAccount();
        $revenueAccount->id = 'acc-rev';

        $taxAccount = new ChartOfAccount();
        $taxAccount->id = 'acc-tax';

        $this->resolveMappingMock->expects($this->exactly(3))
            ->method('execute')
            ->willReturnMap([
                ['bus-1', 'AccountsReceivable', $arAccount],
                ['bus-1', 'SalesRevenue', $revenueAccount],
                ['bus-1', 'SalesTax', $taxAccount],
            ]);

        $this->postingEngineMock->expects($this->once())
            ->method('post')
            ->with($this->callback(function ($dto) {
                return count($dto->lines) === 3
                    && $dto->lines[0]->chartOfAccountId === 'acc-ar'
                    && $dto->lines[0]->type === 'Debit'
                    && $dto->lines[1]->chartOfAccountId === 'acc-rev'
                    && $dto->lines[1]->type === 'Credit'
                    && $dto->lines[2]->chartOfAccountId === 'acc-tax'
                    && $dto->lines[2]->type === 'Credit';
            }))
            ->willReturn(new PostingResultDTO('journal-1', 'JE-100', 'Posted', '2026-07-14'));

        $builder = new SalesPostingBuilder($this->resolveMappingMock, $this->postingEngineMock);
        
        $result = $builder->buildAndPost($this->salesDataMock);

        $this->assertEquals('journal-1', $result->journalEntryId);
    }

    public function test_it_fails_when_account_mapping_fails()
    {
        $this->salesDataMock->method('getAccountsReceivableBase')->willReturn(110.0);

        $this->resolveMappingMock->expects($this->once())
            ->method('execute')
            ->with('bus-1', 'AccountsReceivable')
            ->willThrowException(new \Exception('Mapping not found'));

        $this->postingEngineMock->expects($this->never())->method('post');

        $builder = new SalesPostingBuilder($this->resolveMappingMock, $this->postingEngineMock);
        
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Mapping not found');

        $builder->buildAndPost($this->salesDataMock);
    }

    public function test_it_fails_when_posting_engine_fails()
    {
        $this->salesDataMock->method('getAccountsReceivableBase')->willReturn(110.0);
        $this->salesDataMock->method('getAccountsReceivableForeign')->willReturn(110.0);
        
        $arAccount = new ChartOfAccount();
        $arAccount->id = 'acc-ar';

        $this->resolveMappingMock->method('execute')->willReturn($arAccount);

        $this->postingEngineMock->expects($this->once())
            ->method('post')
            ->willThrowException(new \Exception('Posting failed due to unbalanced lines'));

        $builder = new SalesPostingBuilder($this->resolveMappingMock, $this->postingEngineMock);
        
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Posting failed due to unbalanced lines');

        $builder->buildAndPost($this->salesDataMock);
    }
}
