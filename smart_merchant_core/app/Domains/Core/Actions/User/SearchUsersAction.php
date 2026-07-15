<?php

namespace App\Domains\Core\Actions\User;

use App\Domains\Core\DTOs\UserSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchUsersAction
{
    private const ALLOWED_INCLUDES = ['roles', 'branches'];

    public function __construct(private readonly UserRepositoryInterface $repository) {}

    public function handle(UserSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $validIncludes = array_intersect($criteria->includes, self::ALLOWED_INCLUDES);

        $secureCriteria = new UserSearchCriteriaDTO(
            businessId: $criteria->businessId,
            keyword: $criteria->keyword,
            status: $criteria->status,
            perPage: $criteria->perPage,
            sortField: $criteria->sortField,
            sortDir: $criteria->sortDir,
            includes: $validIncludes
        );

        return $this->repository->search($secureCriteria);
    }
}
