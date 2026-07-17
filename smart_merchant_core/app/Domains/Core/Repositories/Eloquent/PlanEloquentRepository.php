<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\Plan;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\DTOs\PlanListCriteriaDTO;
use App\Domains\Core\DTOs\PlanSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdatePlanDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class PlanEloquentRepository implements PlanRepositoryInterface
{
    public function create(array $data): Plan
    {
        return Plan::create($data);
    }

    public function findById(string $id): ?Plan
    {
        return Plan::find($id);
    }

    public function paginate(PlanListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Plan::orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(PlanSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Plan::query();

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('description', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Plan $plan, UpdatePlanDTO $dto): Plan
    {
        $plan->update($dto->toArray());
        return $plan;
    }

    public function delete(Plan $plan): bool
    {
        return (bool) $plan->delete();
    }

    public function updateStatus(Plan $plan, bool $isActive): Plan
    {
        $plan->update(['is_active' => $isActive]);
        return $plan;
    }

    public function isUsed(Plan $plan): bool
    {
        // Reference Master Data rule: Check if used in operational entities
        // Using DB facade to avoid model dependency issues if Subscription model is not yet fully defined
        return DB::table('subscriptions')->where('plan_id', $plan->id)->exists();
    }
}
