<?php

namespace App\Domains\Core\Actions\Plan;

use App\Models\Core\Plan;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ActivatePlanAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(string $planId): Plan
    {
        $plan = $this->repository->findById($planId);

        if (!$plan) {
            throw new CoreDomainException("The specified plan does not exist.");
        }

        if ($plan->is_active) {
            return $plan;
        }

        return $this->repository->updateStatus($plan, true);
    }
}
