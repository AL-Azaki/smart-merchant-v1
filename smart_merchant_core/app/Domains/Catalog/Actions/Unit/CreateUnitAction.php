<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\Models\Unit;
use App\Domains\Catalog\DTOs\CreateUnitDTO;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class CreateUnitAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(CreateUnitDTO $dto): Unit
    {
        if ($this->repository->existsByCode($dto->unitSymbol, $dto->businessId)) {
            throw new CatalogDomainException("Unit symbol '{$dto->unitSymbol}' already exists.");
        }

        return $this->repository->create($dto->toArray());
    }
}


