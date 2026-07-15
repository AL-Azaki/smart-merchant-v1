<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeactivatePaymentTermAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(string $paymentTermId, string $businessId): PaymentTerm
    {
        $paymentTerm = $this->repository->findById($paymentTermId);

        if (!$paymentTerm || $paymentTerm->business_id !== $businessId) {
            throw new ModelNotFoundException("Payment term not found.");
        }

        return $this->repository->update($paymentTerm, ['is_active' => false]);
    }
}
