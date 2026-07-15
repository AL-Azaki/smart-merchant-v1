<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteTaxAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(string $taxId, string $businessId): bool
    {
        $tax = $this->repository->findById($taxId);

        if (!$tax || $tax->business_id !== $businessId) {
            throw new ModelNotFoundException("Tax not found.");
        }

        if ($this->repository->isUsedInOperations($tax->id)) {
            throw ValidationException::withMessages([
                'id' => 'Cannot delete a tax that has been used in operations. Deactivate it instead.'
            ]);
        }

        return $this->repository->delete($tax);
    }
}
