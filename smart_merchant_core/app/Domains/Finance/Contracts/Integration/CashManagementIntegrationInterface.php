<?php

namespace App\Domains\Finance\Contracts\Integration;

use App\Domains\Finance\Models\Payment;

interface CashManagementIntegrationInterface
{
    public function handlePaymentCashTransaction(Payment $payment): void;
    public function handlePaymentReversalCashTransaction(Payment $payment): void;
    public function resolveRegisterForPayment(Payment $payment): string;
}
