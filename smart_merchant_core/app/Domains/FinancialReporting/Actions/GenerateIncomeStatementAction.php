<?php

namespace App\Domains\FinancialReporting\Actions;

use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\FinancialClosing\Models\AccountingPeriod;

class GenerateIncomeStatementAction
{
    private ReportingDataRepositoryInterface $repository;

    public function __construct(ReportingDataRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId, string $periodId): array
    {
        $period = AccountingPeriod::findOrFail($periodId);

        $balances = $this->repository->getAccountBalances(
            $businessId,
            $period->start_date->toDateString(),
            $period->end_date->toDateString(),
            ['Revenue', 'Expense'] // Only P&L accounts
        );

        $revenues = [];
        $expenses = [];

        $totalRevenue = 0;
        $totalExpenses = 0;

        foreach ($balances as $balance) {
            $net = $balance->total_credit - $balance->total_debit; // Normal balance for revenue is Credit
            if ($balance->account_type === 'Expense') {
                $net = $balance->total_debit - $balance->total_credit; // Normal balance for expense is Debit
            }

            $line = [
                'account_name' => $balance->account_name,
                'account_code' => $balance->account_code,
                'balance' => $net
            ];

            if ($balance->account_type === 'Revenue') {
                $revenues[] = $line;
                $totalRevenue += $net;
            } elseif ($balance->account_type === 'Expense') {
                $expenses[] = $line;
                $totalExpenses += $net;
            }
        }

        $netIncome = $totalRevenue - $totalExpenses;

        return [
            'business_id' => $businessId,
            'period_id' => $periodId,
            'period_name' => $period->period_name,
            'period_status' => $period->status,
            'start_date' => $period->start_date->toDateString(),
            'end_date' => $period->end_date->toDateString(),
            'revenues' => $revenues,
            'total_revenue' => $totalRevenue,
            'expenses' => $expenses,
            'total_expenses' => $totalExpenses,
            'net_income' => $netIncome,
        ];
    }
}
