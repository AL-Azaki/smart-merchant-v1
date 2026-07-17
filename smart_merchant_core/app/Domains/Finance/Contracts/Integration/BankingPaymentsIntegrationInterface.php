<?php

namespace App\Domains\Finance\Contracts\Integration;

use App\Domains\Finance\Models\Payment;

interface BankingPaymentsIntegrationInterface
{
    public function handlePaymentBankTransaction(Payment $payment): void;
    public function handlePaymentReversalBankTransaction(Payment $payment): void;
    public function resolveAccountForPayment(Payment $payment): string;
}
