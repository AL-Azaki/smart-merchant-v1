<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\DTOs\BranchSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchBranchesAction
{
    private const ALLOWED_INCLUDES = ['business', 'users'];

    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(BranchSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $validIncludes = array_intersect($criteria->includes, self::ALLOWED_INCLUDES);

        $secureCriteria = new BranchSearchCriteriaDTO(
            businessId: $criteria->businessId,
            keyword: $criteria->keyword,
            isActive: $criteria->isActive,
            isDefault: $criteria->isDefault,
            perPage: $criteria->perPage,
            sortField: $criteria->sortField,
            sortDir: $criteria->sortDir,
            includes: $validIncludes
        );

        return $this->repository->search($secureCriteria);
    }
}
