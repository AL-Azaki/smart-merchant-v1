<?php

namespace App\Domains\FinancialReporting\Actions;

use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\FinancialClosing\Models\AccountingPeriod;

class GenerateCashFlowStatementAction
{
    private ReportingDataRepositoryInterface $repository;

    public function __construct(ReportingDataRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId, string $periodId): array
    {
        $period = AccountingPeriod::findOrFail($periodId);

        // For a simplified Cash Flow, we look at changes in Cash accounts.
        // In a real indirect method, we'd start with Net Income and adjust for non-cash items and changes in working capital.
        // Here, we'll demonstrate a simplified Direct method approach by looking at entries involving Cash accounts.
        // We'll fetch all balances, but filter for Asset accounts that might be 'Cash'.
        // Assuming we have a way to identify Cash accounts (e.g., account_code starting with 100).
        // Let's just fetch all balances and simulate.

        $openingBalances = $this->repository->getCumulativeBalances(
            $businessId,
            $period->start_date->toDateString(),
            ['Asset']
        );

        $periodBalances = $this->repository->getAccountBalances(
            $businessId,
            $period->start_date->toDateString(),
            $period->end_date->toDateString(),
            ['Asset']
        );

        $openingCash = 0;
        foreach ($openingBalances as $balance) {
            // Pseudo-logic: Identify cash accounts by code (e.g., 1000 to 1099)
            if (str_starts_with($balance->account_code, '100')) {
                $openingCash += ($balance->total_debit - $balance->total_credit);
            }
        }

        $operatingFlows = 0;
        $investingFlows = 0;
        $financingFlows = 0;

        foreach ($periodBalances as $balance) {
            if (str_starts_with($balance->account_code, '100')) {
                $netMove = $balance->total_debit - $balance->total_credit;
                // For a real CF statement, we'd need to trace the opposing side of the journal entry to classify it.
                // Since this is a reporting summary, we'll just bucket everything into Operating for this simplified architecture implementation.
                $operatingFlows += $netMove;
            }
        }

        $netCashFlow = $operatingFlows + $investingFlows + $financingFlows;
        $closingCash = $openingCash + $netCashFlow;

        return [
            'business_id' => $businessId,
            'period_id' => $periodId,
            'period_name' => $period->period_name,
            'period_status' => $period->status,
            'start_date' => $period->start_date->toDateString(),
            'end_date' => $period->end_date->toDateString(),
            'opening_cash_balance' => $openingCash,
            'operating_activities' => $operatingFlows,
            'investing_activities' => $investingFlows,
            'financing_activities' => $financingFlows,
            'net_cash_flow' => $netCashFlow,
            'closing_cash_balance' => $closingCash,
        ];
    }
}
