<?php

namespace App\Domains\Finance\Services\Payment;

use App\Domains\Finance\Models\PaymentAllocation;
use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\DTOs\Integration\InvoiceSettlementRequestDTO;

class InvoiceSettlementBuilder
{
    public function build(Payment $payment, PaymentAllocation $allocation, string $action = 'settle'): InvoiceSettlementRequestDTO
    {
        return new InvoiceSettlementRequestDTO(
            invoiceId: $allocation->document_id,
            amount: (float) $allocation->amount,
            paymentDate: clone $payment->payment_date->format('Y-m-d H:i:s'),
            paymentId: $payment->id,
            action: $action
        );
    }
}
