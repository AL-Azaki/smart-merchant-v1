<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\DTOs\BranchListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListBranchesAction
{
    private const ALLOWED_INCLUDES = ['business', 'users'];

    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(BranchListCriteriaDTO $criteria): LengthAwarePaginator
    {
        // Enforce whitelist for includes
        $validIncludes = array_intersect($criteria->includes, self::ALLOWED_INCLUDES);

        // Rebuild criteria with validated includes to ensure security
        $secureCriteria = new BranchListCriteriaDTO(
            businessId: $criteria->businessId,
            perPage: $criteria->perPage,
            sortField: $criteria->sortField,
            sortDir: $criteria->sortDir,
            includes: $validIncludes
        );

        return $this->repository->paginate($secureCriteria);
    }
}
