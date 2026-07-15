<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ActivateTaxAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(string $taxId, string $businessId): Tax
    {
        $tax = $this->repository->findById($taxId);

        if (!$tax || $tax->business_id !== $businessId) {
            throw new ModelNotFoundException("Tax not found.");
        }

        return $this->repository->update($tax, ['is_active' => true]);
    }
}
