<?php

namespace App\Domains\FinancialReporting\Actions;

use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\FinancialClosing\Models\AccountingPeriod;

class GenerateBalanceSheetAction
{
    private ReportingDataRepositoryInterface $repository;

    public function __construct(ReportingDataRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId, string $asOfDate): array
    {
        // Add 1 day to asOfDate to get balances up to the end of that day
        $beforeDate = date('Y-m-d', strtotime($asOfDate . ' +1 day'));

        $balances = $this->repository->getCumulativeBalances(
            $businessId,
            $beforeDate,
            ['Asset', 'Liability', 'Equity'] // Only balance sheet accounts
        );

        $assets = [];
        $liabilities = [];
        $equity = [];

        $totalAssets = 0;
        $totalLiabilities = 0;
        $totalEquity = 0;

        foreach ($balances as $balance) {
            $net = $balance->total_debit - $balance->total_credit;
            if ($balance->normal_balance === 'Credit') {
                $net = $balance->total_credit - $balance->total_debit;
            }

            $line = [
                'account_name' => $balance->account_name,
                'account_code' => $balance->account_code,
                'balance' => $net
            ];

            if ($balance->account_type === 'Asset') {
                $assets[] = $line;
                $totalAssets += $net;
            } elseif ($balance->account_type === 'Liability') {
                $liabilities[] = $line;
                $totalLiabilities += $net;
            } elseif ($balance->account_type === 'Equity') {
                $equity[] = $line;
                $totalEquity += $net;
            }
        }

        // Calculate Retained Earnings (Net Income from P&L accounts up to beforeDate)
        $plBalances = $this->repository->getCumulativeBalances(
            $businessId,
            $beforeDate,
            ['Revenue', 'Expense'] // P&L accounts
        );

        $retainedEarnings = 0;
        foreach ($plBalances as $balance) {
            $net = $balance->total_credit - $balance->total_debit; // Revenue is credit, Expense is debit
            $retainedEarnings += $net;
        }

        if ($retainedEarnings != 0) {
            $equity[] = [
                'account_name' => 'Retained Earnings (Calculated)',
                'account_code' => 'RE-CALC',
                'balance' => $retainedEarnings
            ];
            $totalEquity += $retainedEarnings;
        }

        $isBalanced = abs($totalAssets - ($totalLiabilities + $totalEquity)) < 0.01;

        return [
            'business_id' => $businessId,
            'as_of_date' => $asOfDate,
            'assets' => $assets,
            'total_assets' => $totalAssets,
            'liabilities' => $liabilities,
            'total_liabilities' => $totalLiabilities,
            'equity' => $equity,
            'total_equity' => $totalEquity,
            'is_balanced' => $isBalanced,
        ];
    }
}
