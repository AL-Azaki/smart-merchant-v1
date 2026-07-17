<?php

namespace App\Domains\Finance\Services\CashManagement;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use RuntimeException;

class CashRegisterResolver
{
    private CashRegisterRepositoryInterface $repository;

    public function __construct(CashRegisterRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    /**
     * Resolves the appropriate open CashRegister for a Payment.
     * Validates that the register is Open and belongs to the same branch.
     */
    public function resolveForPayment(Payment $payment): string
    {
        // The register is expected to be referenced on the payment itself.
        // In the Cash payment flow, the caller must specify the cash_register_id.
        if (empty($payment->cash_register_id)) {
            throw new RuntimeException(
                "Cash payment requires a cash_register_id. Payment #{$payment->payment_number} has none."
            );
        }

        $register = $this->repository->findById($payment->cash_register_id);

        if (! $register) {
            throw new RuntimeException(
                "CashRegister [{$payment->cash_register_id}] not found."
            );
        }

        if ($register->status !== 'Open') {
            throw new RuntimeException(
                "CashRegister [{$register->register_name}] is not Open. Cash transactions require an Open register."
            );
        }

        if ($register->business_id !== $payment->business_id) {
            throw new RuntimeException(
                "CashRegister does not belong to the same Business as Payment #{$payment->payment_number}."
            );
        }

        return $register->id;
    }
}
