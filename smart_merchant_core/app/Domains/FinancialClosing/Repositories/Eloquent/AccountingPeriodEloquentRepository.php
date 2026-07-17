<?php

namespace App\Domains\FinancialClosing\Repositories\Eloquent;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use Illuminate\Support\Collection;

class AccountingPeriodEloquentRepository implements AccountingPeriodRepositoryInterface
{
    public function create(array $data): AccountingPeriod
    {
        return AccountingPeriod::create($data);
    }

    public function update(string $id, array $data): AccountingPeriod
    {
        $period = AccountingPeriod::findOrFail($id);
        $period->update($data);
        return $period->fresh();
    }

    public function findById(string $id): ?AccountingPeriod
    {
        return AccountingPeriod::find($id);
    }

    public function list(array $filters = []): Collection
    {
        $query = AccountingPeriod::query();

        if (isset($filters['business_id'])) {
            $query->where('business_id', $filters['business_id']);
        }
        if (isset($filters['fiscal_year_id'])) {
            $query->where('fiscal_year_id', $filters['fiscal_year_id']);
        }
        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        return $query->orderBy('start_date')->get();
    }

    public function loadAggregate(string $id): ?AccountingPeriod
    {
        return AccountingPeriod::with(['business', 'fiscalYear', 'creator', 'updater', 'closedBy', 'reopenedBy'])->find($id);
    }
}
