<?php

namespace App\Domains\Core\Actions\Permission;

use App\Domains\Core\DTOs\PermissionSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\PermissionRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchPermissionsAction
{
    public function __construct(private readonly PermissionRepositoryInterface $repository) {}

    public function handle(PermissionSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
