<?php

namespace App\Domains\Sales\Services;

use App\Domains\Finance\Actions\AccountMapping\ResolveAccountMappingAction;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\PostingEngine\PostingLineDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use App\Domains\Sales\Contracts\SalesPostingContract;

class SalesPostingBuilder
{
    private ResolveAccountMappingAction $resolveMapping;
    private PostingEngineInterface $postingEngine;

    public function __construct(
        ResolveAccountMappingAction $resolveMapping,
        PostingEngineInterface $postingEngine
    ) {
        $this->resolveMapping = $resolveMapping;
        $this->postingEngine = $postingEngine;
    }

    public function buildAndPost(SalesPostingContract $salesData): PostingResultDTO
    {
        $businessId = $salesData->getBusinessId();

        $lines = [];

        // 1. Accounts Receivable (Debit)
        if ($salesData->getAccountsReceivableBase() > 0) {
            $arAccount = $this->resolveMapping->execute($businessId, 'AccountsReceivable');
            $lines[] = new PostingLineDTO(
                $arAccount->id,
                'Debit',
                $salesData->getAccountsReceivableForeign(),
                $salesData->getAccountsReceivableBase(),
                'Accounts Receivable - ' . $salesData->getDocumentNumber()
            );
        }

        // 2. Sales Discount (Debit)
        if ($salesData->getSalesDiscountBase() > 0) {
            $discountAccount = $this->resolveMapping->execute($businessId, 'SalesDiscount');
            $lines[] = new PostingLineDTO(
                $discountAccount->id,
                'Debit',
                $salesData->getSalesDiscountForeign(),
                $salesData->getSalesDiscountBase(),
                'Sales Discount - ' . $salesData->getDocumentNumber()
            );
        }

        // 3. Sales Revenue (Credit)
        if ($salesData->getSalesRevenueBase() > 0) {
            $revenueAccount = $this->resolveMapping->execute($businessId, 'SalesRevenue');
            $lines[] = new PostingLineDTO(
                $revenueAccount->id,
                'Credit',
                $salesData->getSalesRevenueForeign(),
                $salesData->getSalesRevenueBase(),
                'Sales Revenue - ' . $salesData->getDocumentNumber()
            );
        }

        // 4. Sales Tax (Credit)
        if ($salesData->getSalesTaxBase() > 0) {
            $taxAccount = $this->resolveMapping->execute($businessId, 'SalesTax');
            $lines[] = new PostingLineDTO(
                $taxAccount->id,
                'Credit',
                $salesData->getSalesTaxForeign(),
                $salesData->getSalesTaxBase(),
                'Sales Tax - ' . $salesData->getDocumentNumber()
            );
        }

        $requestDTO = new PostingRequestDTO(
            $businessId,
            $salesData->getFiscalPeriodId(),
            $salesData->getDocumentDate(),
            $salesData->getPostingDate(),
            'SalesInvoice',
            'SalesInvoice',
            $salesData->getDocumentId(),
            $salesData->getDocumentNumber(),
            $salesData->getCurrencyId(),
            $salesData->getExchangeRate(),
            $salesData->getDescription(),
            $salesData->getCreatedBy(),
            $lines
        );

        return $this->postingEngine->post($requestDTO);
    }
}
