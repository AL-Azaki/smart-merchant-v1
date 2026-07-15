<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\DTOs\CreatePaymentTermDTO;
use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreatePaymentTermAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(CreatePaymentTermDTO $dto): PaymentTerm
    {
        $existing = $this->repository->findByName($dto->businessId, $dto->termName);
        if ($existing) {
            throw ValidationException::withMessages([
                'term_name' => 'A payment term with this name already exists for the business.'
            ]);
        }

        $data = [
            'business_id' => $dto->businessId,
            'term_name' => $dto->termName,
            'days_to_due' => $dto->daysToDue,
            'is_active' => $dto->isActive,
        ];

        return $this->repository->create($data);
    }
}
