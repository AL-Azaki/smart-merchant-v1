<?php

namespace App\Domains\FinancialClosing\Actions;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;

class LoadAccountingPeriodAggregateAction
{
    private AccountingPeriodRepositoryInterface $repository;

    public function __construct(AccountingPeriodRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): ?AccountingPeriod
    {
        return $this->repository->loadAggregate($id);
    }
}
