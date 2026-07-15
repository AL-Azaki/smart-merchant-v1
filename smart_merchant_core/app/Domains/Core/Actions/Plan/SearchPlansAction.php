<?php

namespace App\Domains\Core\Actions\Plan;

use App\Domains\Core\DTOs\PlanSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchPlansAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(PlanSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
