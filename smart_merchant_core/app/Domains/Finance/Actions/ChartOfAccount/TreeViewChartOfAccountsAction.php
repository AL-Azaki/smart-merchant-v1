<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;

class TreeViewChartOfAccountsAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(string $businessId): Collection
    {
        return $this->repository->getTree($businessId);
    }
}
