<?php

namespace App\Domains\Finance\Actions\AccountMapping;

use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;

class UpdateAccountMappingAction
{
    private AccountMappingRepositoryInterface $repository;

    public function __construct(AccountMappingRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(AccountMapping $accountMapping, array $data): AccountMapping
    {
        return $this->repository->update($accountMapping, $data);
    }
}
