<?php

namespace App\Domains\Core\Actions\Plan;

use App\Models\Core\Plan;
use App\Domains\Core\DTOs\UpdatePlanDTO;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdatePlanAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(string $planId, UpdatePlanDTO $dto): Plan
    {
        $plan = $this->repository->findById($planId);

        if (!$plan) {
            throw new CoreDomainException("The specified plan does not exist.");
        }

        return $this->repository->update($plan, $dto);
    }
}
