<?php

namespace App\Domains\Sales\Contracts;

interface SalesPostingContract
{
    public function getBusinessId(): string;
    public function getFiscalPeriodId(): string;
    public function getDocumentDate(): string;
    public function getPostingDate(): string;
    public function getDocumentId(): string;
    public function getDocumentNumber(): string;
    public function getCurrencyId(): string;
    public function getExchangeRate(): float;
    public function getDescription(): string;
    public function getCreatedBy(): string;

    public function getAccountsReceivableForeign(): float;
    public function getAccountsReceivableBase(): float;

    public function getSalesRevenueForeign(): float;
    public function getSalesRevenueBase(): float;

    public function getSalesTaxForeign(): float;
    public function getSalesTaxBase(): float;

    public function getSalesDiscountForeign(): float;
    public function getSalesDiscountBase(): float;
}
