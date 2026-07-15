<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Models\Core\Plan;

interface PlanRepositoryInterface
{
    public function create(array $data): Plan;

    public function findById(string $id): ?Plan;

    public function paginate(\App\Domains\Core\DTOs\PlanListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\PlanSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Plan $plan, \App\Domains\Core\DTOs\UpdatePlanDTO $dto): Plan;

    public function delete(Plan $plan): bool;

    public function updateStatus(Plan $plan, bool $isActive): Plan;

    public function isUsed(Plan $plan): bool;
}
