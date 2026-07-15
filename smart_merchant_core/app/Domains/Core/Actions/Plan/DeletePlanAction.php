<?php

namespace App\Domains\Core\Actions\Plan;

use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class DeletePlanAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(string $planId): void
    {
        $plan = $this->repository->findById($planId);

        if (!$plan) {
            throw new CoreDomainException("The specified plan does not exist.");
        }

        if ($this->repository->isUsed($plan)) {
            throw new CoreDomainException("Cannot delete plan because it is currently linked to one or more subscriptions. Please deactivate it instead.");
        }

        $this->repository->delete($plan);
    }
}
