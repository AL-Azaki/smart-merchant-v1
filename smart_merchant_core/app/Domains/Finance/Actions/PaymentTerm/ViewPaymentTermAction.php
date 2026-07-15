<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\DTOs\ViewPaymentTermDTO;
use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewPaymentTermAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(ViewPaymentTermDTO $dto): PaymentTerm
    {
        $paymentTerm = $this->repository->findById($dto->paymentTermId);

        if (!$paymentTerm || $paymentTerm->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Payment term not found.");
        }

        return $paymentTerm;
    }
}
