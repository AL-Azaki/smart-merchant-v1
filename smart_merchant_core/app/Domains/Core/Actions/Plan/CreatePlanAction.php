<?php

namespace App\Domains\Core\Actions\Plan;

use App\Models\Core\Plan;
use App\Domains\Core\DTOs\CreatePlanDTO;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;

class CreatePlanAction
{
    public function __construct(private readonly PlanRepositoryInterface $repository) {}

    public function handle(CreatePlanDTO $dto): Plan
    {
        return $this->repository->create([
            'name'           => $dto->name,
            'description'    => $dto->description,
            'monthly_price'  => $dto->monthlyPrice,
            'annual_price'   => $dto->annualPrice,
            'max_businesses' => $dto->maxBusinesses,
            'max_users'      => $dto->maxUsers,
            'features'       => $dto->features !== null ? json_encode($dto->features) : null,
            'is_active'      => true,
        ]);
    }
}
