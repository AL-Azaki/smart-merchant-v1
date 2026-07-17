<?php

namespace App\Domains\FinancialClosing\Services\Integration;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use RuntimeException;

class PeriodPostingAuthorizationService
{
    /**
     * Validates that a Journal Entry may be posted within the given fiscal period.
     * Called by the General Ledger domain before posting any JournalEntry.
     *
     * @param string $businessId
     * @param string $fiscalPeriodId
     * @return bool
     * @throws RuntimeException
     */
    public function authorizePosting(string $businessId, string $fiscalPeriodId): bool
    {
        $period = AccountingPeriod::where('business_id', $businessId)
            ->where('fiscal_year_id', $fiscalPeriodId)
            ->first();

        if (!$period) {
            throw new RuntimeException("No accounting period found for the given fiscal period.");
        }

        if (!in_array($period->status, ['Open', 'Reopened'])) {
            throw new RuntimeException("Posting rejected: Accounting period '{$period->period_name}' is {$period->status}.");
        }

        return true;
    }

    /**
     * Resolves the current status of an accounting period.
     *
     * @param string $businessId
     * @param string $fiscalPeriodId
     * @return string|null
     */
    public function resolvePeriodStatus(string $businessId, string $fiscalPeriodId): ?string
    {
        $period = AccountingPeriod::where('business_id', $businessId)
            ->where('fiscal_year_id', $fiscalPeriodId)
            ->first();

        return $period?->status;
    }
}
