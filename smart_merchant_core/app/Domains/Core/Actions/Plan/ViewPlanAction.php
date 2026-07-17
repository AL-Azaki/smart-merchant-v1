<?php

namespace App\Domains\Core\Actions\Plan;

use App\Domains\Core\Models\Plan;
use App\Domains\Core\DTOs\ViewPlanDTO;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewPlanAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(ViewPlanDTO $dto): Plan
    {
        $plan = $this->repository->findById($dto->planId);

        if (!$plan) {
            throw new CoreDomainException("The specified plan does not exist.");
        }

        return $plan;
    }
}
