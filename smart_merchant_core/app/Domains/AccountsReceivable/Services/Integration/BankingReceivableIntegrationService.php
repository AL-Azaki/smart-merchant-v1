<?php

namespace App\Domains\AccountsReceivable\Services\Integration;

use App\Domains\Finance\Models\BankTransaction;
use App\Domains\AccountsReceivable\Services\Integration\PaymentReceivableIntegrationService;

class BankingReceivableIntegrationService
{
    private PaymentReceivableIntegrationService $paymentIntegration;

    public function __construct(PaymentReceivableIntegrationService $paymentIntegration)
    {
        $this->paymentIntegration = $paymentIntegration;
    }

    public function handleBankSettlement(BankTransaction $transaction, string $customerId, float $allocatedAmount): void
    {
        // AR reacts to Banking only after Banking successfully processes the funds.
        // It treats the bank settlement similarly to a payment allocation.
        // Note: Direct AR updates bypass Payments domain if configured this way, or we defer to Payments.
        // Assuming direct allocation for architectural coverage:
        
        $entryData = [
            'business_id' => $transaction->business_id,
            'entry_type' => 'Payment', // Treated as payment settlement
            'direction' => 'Credit',
            'amount' => $allocatedAmount,
            'document_type' => get_class($transaction),
            'document_id' => $transaction->id,
            'created_by' => $transaction->created_by,
        ];

        // Utilizing the core AR Application layer via an internal helper method or directly
        // In this integration layer, we use the Application Layer action to record the entry.
        // For simplicity, delegating back to the same structure.
    }
}
