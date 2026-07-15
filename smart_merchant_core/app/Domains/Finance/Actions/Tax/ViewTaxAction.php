<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\DTOs\ViewTaxDTO;
use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewTaxAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(ViewTaxDTO $dto): Tax
    {
        $tax = $this->repository->findById($dto->taxId);

        if (!$tax || $tax->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Tax not found.");
        }

        return $tax;
    }
}
