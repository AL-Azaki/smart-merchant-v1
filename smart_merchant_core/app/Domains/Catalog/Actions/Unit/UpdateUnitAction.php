<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\Models\Unit;
use App\Domains\Catalog\DTOs\UpdateUnitDTO;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class UpdateUnitAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(Unit $unit, UpdateUnitDTO $dto): Unit
    {
        // Note: Unit code is intentionally omitted from UpdateUnitDTO (Immutable Rule).

        return $this->repository->update($unit, $dto);
    }
}


