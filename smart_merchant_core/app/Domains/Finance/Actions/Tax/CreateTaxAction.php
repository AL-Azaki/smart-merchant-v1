<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\DTOs\CreateTaxDTO;
use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreateTaxAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(CreateTaxDTO $dto): Tax
    {
        $existing = $this->repository->findByName($dto->businessId, $dto->taxName);
        if ($existing) {
            throw ValidationException::withMessages([
                'tax_name' => 'A tax with this name already exists for the business.'
            ]);
        }

        $data = [
            'business_id' => $dto->businessId,
            'tax_name' => $dto->taxName,
            'tax_rate' => $dto->taxRate,
            'is_active' => $dto->isActive,
        ];

        return $this->repository->create($data);
    }
}
