<?php

namespace App\Domains\Finance\Services\CashManagement;

use App\Domains\Finance\Models\Payment;

class PaymentCashTransactionBuilder
{
    /**
     * Converts a Payment into a CashTransaction data array.
     * Contains no Business Logic — it is a pure data transformer.
     */
    public function build(Payment $payment): array
    {
        $transactionType = $this->resolveTransactionType($payment);

        return [
            'business_id' => $payment->business_id,
            'transaction_type' => $transactionType,
            'amount' => $payment->amount,
            'document_type' => Payment::class,
            'document_id' => $payment->id,
            'notes' => "Cash transaction for Payment #{$payment->payment_number}",
            'created_by' => $payment->created_by,
            'created_at' => now(),
        ];
    }

    /**
     * Converts a Payment Reversal into a compensatory CashTransaction data array.
     */
    public function buildReversal(Payment $payment): array
    {
        $originalTransactionType = $this->resolveTransactionType($payment);
        $reversalType = $this->resolveReversalType($originalTransactionType);

        return [
            'business_id' => $payment->business_id,
            'transaction_type' => $reversalType,
            'amount' => $payment->amount,
            'document_type' => Payment::class,
            'document_id' => $payment->id,
            'notes' => "Cash reversal for Payment #{$payment->payment_number}",
            'created_by' => $payment->created_by,
            'created_at' => now(),
        ];
    }

    private function resolveTransactionType(Payment $payment): string
    {
        // direction is determined by the payment type
        // 'receipt' = cash received from customer (inflow)
        // 'payment' = cash paid to supplier (outflow)
        return match ($payment->payment_type) {
            'receipt' => 'Receipt',
            'payment' => 'Payment',
            default => 'Deposit',
        };
    }

    private function resolveReversalType(string $originalType): string
    {
        return match ($originalType) {
            'Receipt' => 'Withdrawal',
            'Payment' => 'Deposit',
            default => 'Adjustment',
        };
    }
}
