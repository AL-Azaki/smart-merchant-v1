<?php

namespace App\Domains\Core\Actions\Role;

use App\Domains\Core\DTOs\RoleListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListRolesAction
{
    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(RoleListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
