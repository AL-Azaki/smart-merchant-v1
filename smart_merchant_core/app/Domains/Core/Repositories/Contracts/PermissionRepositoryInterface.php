<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\Permission;

interface PermissionRepositoryInterface
{
    public function findById(string $id): ?Permission;

    public function paginate(\App\Domains\Core\DTOs\PermissionListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\PermissionSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function existsAll(array $ids): bool;
}
