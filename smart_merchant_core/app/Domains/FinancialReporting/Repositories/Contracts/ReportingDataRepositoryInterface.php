<?php

namespace App\Domains\FinancialReporting\Repositories\Contracts;

use Illuminate\Support\Collection;

interface ReportingDataRepositoryInterface
{
    /**
     * Retrieve aggregated account balances (sum of debits, sum of credits) for posted entries
     * within a date range, scoped by business.
     */
    public function getAccountBalances(string $businessId, string $startDate, string $endDate, array $accountTypes = []): Collection;

    /**
     * Retrieve cumulative account balances from inception up to (but not including) a given date.
     * Used for opening balances.
     */
    public function getCumulativeBalances(string $businessId, string $beforeDate, array $accountTypes = []): Collection;

    /**
     * Retrieve detailed journal entry lines for a specific account within a date range.
     * Used for the General Ledger Report.
     */
    public function getAccountTransactions(string $businessId, string $accountId, string $startDate, string $endDate): Collection;

    /**
     * Retrieve cumulative balance for a single account up to (but not including) a given date.
     * Used for opening balance on General Ledger Report.
     */
    public function getAccountCumulativeBalance(string $businessId, string $accountId, string $beforeDate): array;
}
