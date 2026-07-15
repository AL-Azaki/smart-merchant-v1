<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\DTOs\UpdateTaxDTO;
use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdateTaxAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(UpdateTaxDTO $dto): Tax
    {
        $tax = $this->repository->findById($dto->taxId);

        if (!$tax || $tax->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Tax not found.");
        }

        if ($tax->tax_name !== $dto->taxName) {
            $existing = $this->repository->findByName($dto->businessId, $dto->taxName);
            if ($existing && $existing->id !== $tax->id) {
                throw ValidationException::withMessages([
                    'tax_name' => 'A tax with this name already exists for the business.'
                ]);
            }
        }

        // Updating tax rate doesn't affect old transactions because they took a snapshot.
        $data = [
            'tax_name' => $dto->taxName,
            'tax_rate' => $dto->taxRate,
        ];

        return $this->repository->update($tax, $data);
    }
}
