<?php

namespace App\Domains\FinancialClosing\Services\Integration;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use Illuminate\Support\Collection;

class FinancePeriodResolutionService
{
    /**
     * Resolves the currently active (Open or Reopened) accounting period for a business.
     *
     * @param string $businessId
     * @return AccountingPeriod|null
     */
    public function resolveActivePeriod(string $businessId): ?AccountingPeriod
    {
        return AccountingPeriod::where('business_id', $businessId)
            ->whereIn('status', ['Open', 'Reopened'])
            ->orderBy('start_date', 'desc')
            ->first();
    }

    /**
     * Resolves the status of a specific accounting period by its ID.
     *
     * @param string $periodId
     * @return string|null
     */
    public function resolvePeriodStatus(string $periodId): ?string
    {
        $period = AccountingPeriod::find($periodId);
        return $period?->status;
    }

    /**
     * Checks whether a specific accounting period is available for transactions.
     *
     * @param string $periodId
     * @return bool
     */
    public function isPeriodAvailable(string $periodId): bool
    {
        $period = AccountingPeriod::find($periodId);

        if (!$period) {
            return false;
        }

        return in_array($period->status, ['Open', 'Reopened']);
    }

    /**
     * Lists all accounting periods for a business within a fiscal year.
     *
     * @param string $businessId
     * @param string $fiscalYearId
     * @return Collection
     */
    public function listPeriodsForFiscalYear(string $businessId, string $fiscalYearId): Collection
    {
        return AccountingPeriod::where('business_id', $businessId)
            ->where('fiscal_year_id', $fiscalYearId)
            ->orderBy('start_date')
            ->get(['id', 'period_name', 'start_date', 'end_date', 'status']);
    }
}
