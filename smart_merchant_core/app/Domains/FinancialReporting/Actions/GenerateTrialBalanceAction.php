<?php

namespace App\Domains\FinancialReporting\Actions;

use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\FinancialClosing\Services\Integration\FinancePeriodResolutionService;
use RuntimeException;
use Illuminate\Support\Collection;

class GenerateTrialBalanceAction
{
    private ReportingDataRepositoryInterface $repository;
    private FinancePeriodResolutionService $periodService;

    public function __construct(
        ReportingDataRepositoryInterface $repository,
        FinancePeriodResolutionService $periodService
    ) {
        $this->repository = $repository;
        $this->periodService = $periodService;
    }

    public function execute(string $businessId, string $periodId): array
    {
        $periodStatus = $this->periodService->resolvePeriodStatus($periodId);
        if (!$periodStatus) {
            throw new RuntimeException("Accounting period not found.");
        }

        // Fetch period details (in a real scenario, we'd fetch the period model, but for now we assume we have dates or we pass them)
        // Let's assume the periodService or repository can fetch the period dates.
        // For simplicity, let's assume we pass start_date and end_date to the action or fetch them here.
        // We will fetch the period model directly for dates since it's read-only.
        $period = \App\Domains\FinancialClosing\Models\AccountingPeriod::findOrFail($periodId);

        $balances = $this->repository->getAccountBalances(
            $businessId,
            $period->start_date->toDateString(),
            $period->end_date->toDateString()
        );

        $totalDebit = 0;
        $totalCredit = 0;

        $lines = $balances->map(function ($balance) use (&$totalDebit, &$totalCredit) {
            $totalDebit += $balance->total_debit;
            $totalCredit += $balance->total_credit;

            $netBalance = $balance->total_debit - $balance->total_credit;
            if ($balance->normal_balance === 'Credit') {
                $netBalance = $balance->total_credit - $balance->total_debit;
            }

            return [
                'account_id' => $balance->account_id,
                'account_name' => $balance->account_name,
                'account_code' => $balance->account_code,
                'account_type' => $balance->account_type,
                'total_debit' => $balance->total_debit,
                'total_credit' => $balance->total_credit,
                'net_balance' => $netBalance,
            ];
        });

        // Balance Validation Policy: Total Debit MUST = Total Credit
        // Due to floating point math, a small epsilon might be needed, but ideally they match exactly.
        $isBalanced = abs($totalDebit - $totalCredit) < 0.01;

        return [
            'business_id' => $businessId,
            'period_id' => $periodId,
            'period_name' => $period->period_name,
            'period_status' => $period->status,
            'start_date' => $period->start_date->toDateString(),
            'end_date' => $period->end_date->toDateString(),
            'is_balanced' => $isBalanced,
            'total_debit' => $totalDebit,
            'total_credit' => $totalCredit,
            'lines' => $lines,
        ];
    }
}
