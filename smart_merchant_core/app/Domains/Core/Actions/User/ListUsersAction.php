<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\DTOs\UserListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListUsersAction
{
    private const ALLOWED_INCLUDES = ['roles', 'branches'];

    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(UserListCriteriaDTO $criteria): LengthAwarePaginator
    {
        $validIncludes = array_intersect($criteria->includes, self::ALLOWED_INCLUDES);

        $secureCriteria = new UserListCriteriaDTO(
            businessId: $criteria->businessId,
            perPage: $criteria->perPage,
            sortField: $criteria->sortField,
            sortDir: $criteria->sortDir,
            includes: $validIncludes
        );

        return $this->repository->paginate($secureCriteria);
    }
}
