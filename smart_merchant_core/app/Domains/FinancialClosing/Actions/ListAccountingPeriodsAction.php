<?php

namespace App\Domains\FinancialClosing\Actions;

use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use Illuminate\Support\Collection;

class ListAccountingPeriodsAction
{
    private AccountingPeriodRepositoryInterface $repository;

    public function __construct(AccountingPeriodRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $filters = []): Collection
    {
        return $this->repository->list($filters);
    }
}
