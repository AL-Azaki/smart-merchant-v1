<?php

namespace App\Domains\Finance\Services\Banking;

use App\Domains\Finance\Models\Payment;

class PaymentBankTransactionBuilder
{
    /**
     * Converts a Payment into a BankTransaction data array.
     * Contains NO business logic — pure data transformation only.
     */
    public function build(Payment $payment): array
    {
        $direction = $this->resolveDirection($payment);
        $transactionType = $this->resolveTransactionType($payment);

        return [
            'business_id' => $payment->business_id,
            'transaction_type' => $transactionType,
            'direction' => $direction,
            'amount' => $payment->amount,
            'document_type' => Payment::class,
            'document_id' => $payment->id,
            'notes' => "Bank transaction for Payment #{$payment->payment_number}",
            'created_by' => $payment->created_by,
        ];
    }

    /**
     * Converts a Payment Reversal into a compensatory BankTransaction data array.
     */
    public function buildReversal(Payment $payment): array
    {
        $originalDirection = $this->resolveDirection($payment);
        $reversalDirection = $originalDirection === 'Credit' ? 'Debit' : 'Credit';

        return [
            'business_id' => $payment->business_id,
            'transaction_type' => 'Adjustment',
            'direction' => $reversalDirection,
            'amount' => $payment->amount,
            'document_type' => Payment::class,
            'document_id' => $payment->id,
            'notes' => "Bank reversal for Payment #{$payment->payment_number}",
            'created_by' => $payment->created_by,
        ];
    }

    private function resolveDirection(Payment $payment): string
    {
        return match ($payment->payment_type) {
            'receipt' => 'Credit',   // Money coming in
            'payment' => 'Debit',    // Money going out
            default => 'Credit',
        };
    }

    private function resolveTransactionType(Payment $payment): string
    {
        return match ($payment->payment_type) {
            'receipt' => 'Deposit',
            'payment' => 'Withdrawal',
            default => 'Deposit',
        };
    }
}
