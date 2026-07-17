<?php

namespace App\Domains\FinancialClosing\Repositories\Contracts;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use Illuminate\Support\Collection;

interface AccountingPeriodRepositoryInterface
{
    public function create(array $data): AccountingPeriod;

    public function update(string $id, array $data): AccountingPeriod;

    public function findById(string $id): ?AccountingPeriod;

    public function list(array $filters = []): Collection;

    public function loadAggregate(string $id): ?AccountingPeriod;
}
