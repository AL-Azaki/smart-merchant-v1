<?php

namespace App\Domains\Core\Actions\Role;

use App\Domains\Core\DTOs\RoleSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchRolesAction
{
    public function __construct(private readonly RoleRepositoryInterface $repository) {}

    public function handle(RoleSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
