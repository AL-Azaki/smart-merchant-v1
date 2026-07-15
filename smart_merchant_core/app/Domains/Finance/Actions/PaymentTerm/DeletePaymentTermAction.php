<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeletePaymentTermAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(string $paymentTermId, string $businessId): bool
    {
        $paymentTerm = $this->repository->findById($paymentTermId);

        if (!$paymentTerm || $paymentTerm->business_id !== $businessId) {
            throw new ModelNotFoundException("Payment term not found.");
        }

        if ($this->repository->isUsedInOperations($paymentTerm->id)) {
            throw ValidationException::withMessages([
                'id' => 'Cannot delete a payment term that has been used in operations. Deactivate it instead.'
            ]);
        }

        return $this->repository->delete($paymentTerm);
    }
}
