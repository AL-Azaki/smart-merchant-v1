<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class DeleteUnitAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(Unit $unit): void
    {

        if ($this->repository->isUsed($unit)) {
            throw new CatalogDomainException("Cannot delete Unit because it is used in operational entities. Please deactivate it instead.");
        }

        $this->repository->delete($unit);
    }
}


