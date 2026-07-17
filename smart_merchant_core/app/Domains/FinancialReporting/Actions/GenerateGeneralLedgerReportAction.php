<?php

namespace App\Domains\FinancialReporting\Actions;

use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\FinancialClosing\Models\AccountingPeriod;
use RuntimeException;

class GenerateGeneralLedgerReportAction
{
    private ReportingDataRepositoryInterface $repository;

    public function __construct(ReportingDataRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId, string $periodId, string $accountId): array
    {
        $period = AccountingPeriod::findOrFail($periodId);

        // Get opening balance
        $openingBalances = $this->repository->getAccountCumulativeBalance(
            $businessId,
            $accountId,
            $period->start_date->toDateString()
        );

        $transactions = $this->repository->getAccountTransactions(
            $businessId,
            $accountId,
            $period->start_date->toDateString(),
            $period->end_date->toDateString()
        );

        // Fetch account normal balance to calculate running balance correctly
        $account = \App\Domains\Finance\Models\ChartOfAccount::findOrFail($accountId);

        $openingNet = $openingBalances['total_debit'] - $openingBalances['total_credit'];
        if ($account->normal_balance === 'Credit') {
            $openingNet = $openingBalances['total_credit'] - $openingBalances['total_debit'];
        }

        $runningBalance = $openingNet;

        $lines = $transactions->map(function ($txn) use (&$runningBalance, $account) {
            $netMove = $txn->debit_amount - $txn->credit_amount;
            if ($account->normal_balance === 'Credit') {
                $netMove = $txn->credit_amount - $txn->debit_amount;
            }
            $runningBalance += $netMove;

            return [
                'journal_entry_id' => $txn->journal_entry_id,
                'journal_number' => $txn->journal_number,
                'posting_date' => $txn->posting_date,
                'description' => $txn->line_description ?: $txn->journal_description,
                'debit_amount' => $txn->debit_amount,
                'credit_amount' => $txn->credit_amount,
                'running_balance' => $runningBalance,
            ];
        });

        return [
            'business_id' => $businessId,
            'period_id' => $periodId,
            'period_name' => $period->period_name,
            'period_status' => $period->status,
            'account_id' => $accountId,
            'account_name' => $account->account_name,
            'account_code' => $account->account_code,
            'opening_balance' => $openingNet,
            'closing_balance' => $runningBalance,
            'lines' => $lines,
        ];
    }
}
