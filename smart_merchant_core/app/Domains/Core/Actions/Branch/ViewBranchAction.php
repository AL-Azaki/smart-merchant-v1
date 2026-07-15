<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Models\Branch;
use App\Domains\Core\DTOs\ViewBranchDTO;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewBranchAction
{
    private const ALLOWED_INCLUDES = ['business', 'users'];

    public function __construct(private readonly BranchRepositoryInterface $repository) {}

    public function handle(ViewBranchDTO $dto): Branch
    {
        $validIncludes = array_intersect($dto->includes, self::ALLOWED_INCLUDES);

        $branch = $this->repository->findByIdWithRelations($dto->branchId, $validIncludes);

        if (!$branch) {
            throw new CoreDomainException("The specified branch does not exist.");
        }

        return $branch;
    }
}
