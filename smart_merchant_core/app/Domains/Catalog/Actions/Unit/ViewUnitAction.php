<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\Models\Unit;
use App\Domains\Catalog\DTOs\ViewUnitDTO;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class ViewUnitAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(ViewUnitDTO $dto): Unit
    {
        $unit = $this->repository->findById($dto->UnitId);

        if (!$unit) {
            throw new CatalogDomainException("The specified Unit does not exist.");
        }

        return $unit;
    }
}


