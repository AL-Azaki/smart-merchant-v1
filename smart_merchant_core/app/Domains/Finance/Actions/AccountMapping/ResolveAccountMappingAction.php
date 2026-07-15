<?php

namespace App\Domains\Finance\Actions\AccountMapping;

use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;

class ResolveAccountMappingAction
{
    private AccountMappingRepositoryInterface $repository;

    public function __construct(AccountMappingRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    /**
     * Resolves the Chart of Account for a specific mapping type.
     * 
     * @param string $businessId
     * @param string $mappingType
     * @return ChartOfAccount
     * @throws \Exception
     */
    public function execute(string $businessId, string $mappingType): ChartOfAccount
    {
        $mapping = $this->repository->findByMappingType($businessId, $mappingType);

        if (!$mapping) {
            throw new \Exception("Account Mapping not found for type: {$mappingType}");
        }

        $chartOfAccount = $mapping->chartOfAccount;

        if (!$chartOfAccount || !$chartOfAccount->is_active || !$chartOfAccount->allow_posting) {
            throw new \Exception("Resolved Account for type {$mappingType} is either inactive or not allowed for posting.");
        }

        return $chartOfAccount;
    }
}
