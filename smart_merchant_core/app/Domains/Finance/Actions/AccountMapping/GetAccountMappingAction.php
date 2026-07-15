<?php

namespace App\Domains\Finance\Actions\AccountMapping;

use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;

class GetAccountMappingAction
{
    private AccountMappingRepositoryInterface $repository;

    public function __construct(AccountMappingRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId, string $mappingType): ?AccountMapping
    {
        return $this->repository->findByMappingType($businessId, $mappingType);
    }
}
