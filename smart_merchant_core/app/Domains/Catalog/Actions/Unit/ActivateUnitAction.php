<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\Models\Unit;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class ActivateUnitAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(Unit $unit): Unit
    {
        if ($unit->is_active) {
            return $unit;
        }

        return $this->repository->updateStatus($unit, true);
    }
}


