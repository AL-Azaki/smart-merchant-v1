<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\Branch;

interface BranchRepositoryInterface
{
    public function create(array $data): Branch;

    public function findById(string $id): ?Branch;

    public function existsByCodeInBusiness(string $businessId, string $branchCode): bool;

    public function findByIdWithRelations(string $id, array $relations = []): ?Branch;

    public function paginate(\App\Domains\Core\DTOs\BranchListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\BranchSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Branch $branch, \App\Domains\Core\DTOs\UpdateBranchDTO $dto): Branch;

    public function removeDefaultForBusiness(string $businessId): void;

    public function setAsDefault(Branch $branch): Branch;

    public function updateStatus(Branch $branch, bool $isActive): Branch;

    public function countByBusiness(string $businessId): int;

    public function delete(Branch $branch): bool;
}
