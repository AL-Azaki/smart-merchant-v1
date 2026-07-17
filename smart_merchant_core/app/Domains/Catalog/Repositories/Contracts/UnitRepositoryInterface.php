<?php

namespace App\Domains\Catalog\Repositories\Contracts;

use App\Domains\Catalog\Models\Unit;

interface UnitRepositoryInterface
{
    public function create(array $data): Unit;

    public function findById(string $id): ?Unit;

    public function existsByCode(string $code, ?string $businessId = null): bool;

    public function paginate(\App\Domains\Catalog\DTOs\UnitListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Catalog\DTOs\UnitSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Unit $unit, \App\Domains\Catalog\DTOs\UpdateUnitDTO $dto): Unit;

    public function delete(Unit $unit): bool;

    public function updateStatus(Unit $unit, bool $isActive): Unit;

    
    public function isUsed(Unit $unit): bool;
}


