<?php

namespace App\Domains\Core\Actions\Permission;

use App\Domains\Core\DTOs\PermissionListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\PermissionRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListPermissionsAction
{
    public function __construct(private readonly PermissionRepositoryInterface $repository) {}

    public function handle(PermissionListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
