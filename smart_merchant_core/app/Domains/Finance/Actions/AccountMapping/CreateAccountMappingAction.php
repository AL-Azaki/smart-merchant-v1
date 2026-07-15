<?php

namespace App\Domains\Finance\Actions\AccountMapping;

use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;

class CreateAccountMappingAction
{
    private AccountMappingRepositoryInterface $repository;

    public function __construct(AccountMappingRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): AccountMapping
    {
        if ($this->repository->checkMappingExists($data['business_id'], $data['mapping_type'])) {
            throw new \Exception("Mapping already exists for this type in this business.");
        }

        return $this->repository->create($data);
    }
}
