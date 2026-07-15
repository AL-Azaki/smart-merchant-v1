<?php

namespace App\Domains\Core\Actions\Plan;

use App\Domains\Core\DTOs\PlanListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListPlansAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(PlanListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
