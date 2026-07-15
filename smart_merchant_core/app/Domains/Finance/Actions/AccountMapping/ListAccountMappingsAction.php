<?php

namespace App\Domains\Finance\Actions\AccountMapping;

use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;
use Illuminate\Support\Collection;

class ListAccountMappingsAction
{
    private AccountMappingRepositoryInterface $repository;

    public function __construct(AccountMappingRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId): Collection
    {
        return $this->repository->findByBusiness($businessId);
    }
}
