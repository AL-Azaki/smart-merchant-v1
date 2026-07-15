<?php

namespace App\Domains\Finance\Actions\AccountMapping;

use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;

class DeleteAccountMappingAction
{
    private AccountMappingRepositoryInterface $repository;

    public function __construct(AccountMappingRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(AccountMapping $accountMapping): bool
    {
        return $this->repository->delete($accountMapping);
    }
}
