<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\DTOs\UpdatePaymentTermDTO;
use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdatePaymentTermAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(UpdatePaymentTermDTO $dto): PaymentTerm
    {
        $paymentTerm = $this->repository->findById($dto->paymentTermId);

        if (!$paymentTerm || $paymentTerm->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Payment term not found.");
        }

        if ($paymentTerm->term_name !== $dto->termName) {
            $existing = $this->repository->findByName($dto->businessId, $dto->termName);
            if ($existing && $existing->id !== $paymentTerm->id) {
                throw ValidationException::withMessages([
                    'term_name' => 'A payment term with this name already exists for the business.'
                ]);
            }
        }

        $data = [
            'term_name' => $dto->termName,
            'days_to_due' => $dto->daysToDue,
        ];

        return $this->repository->update($paymentTerm, $data);
    }
}
