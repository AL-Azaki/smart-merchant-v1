<?php

namespace App\Domains\Finance\DTOs\Integration;

class InvoiceSettlementRequestDTO
{
    public string $invoiceId;
    public float $amount;
    public string $paymentDate;
    public string $paymentId;
    public string $action;

    public function __construct(
        string $invoiceId,
        float $amount,
        string $paymentDate,
        string $paymentId,
        string $action = 'settle'
    ) {
        $this->invoiceId = $invoiceId;
        $this->amount = $amount;
        $this->paymentDate = $paymentDate;
        $this->paymentId = $paymentId;
        $this->action = $action;
    }
}
