<?php

namespace App\Domains\FinancialReporting\Repositories\Eloquent;

use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\Finance\Models\JournalEntry;
use App\Domains\Finance\Models\JournalEntryLine;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ReportingDataEloquentRepository implements ReportingDataRepositoryInterface
{
    public function getAccountBalances(string $businessId, string $startDate, string $endDate, array $accountTypes = []): Collection
    {
        $query = DB::table('journal_entry_lines as jel')
            ->join('journal_entries as je', 'jel.journal_entry_id', '=', 'je.id')
            ->join('chart_of_accounts as coa', 'jel.account_id', '=', 'coa.id')
            ->where('je.business_id', $businessId)
            ->where('je.status', 'Posted')
            ->whereBetween('je.posting_date', [$startDate, $endDate])
            ->groupBy('jel.account_id', 'coa.account_name', 'coa.account_code', 'coa.account_type', 'coa.normal_balance')
            ->select(
                'jel.account_id',
                'coa.account_name',
                'coa.account_code',
                'coa.account_type',
                'coa.normal_balance',
                DB::raw('COALESCE(SUM(jel.debit_amount), 0) as total_debit'),
                DB::raw('COALESCE(SUM(jel.credit_amount), 0) as total_credit')
            )
            ->orderBy('coa.account_code');

        if (!empty($accountTypes)) {
            $query->whereIn('coa.account_type', $accountTypes);
        }

        return $query->get();
    }

    public function getCumulativeBalances(string $businessId, string $beforeDate, array $accountTypes = []): Collection
    {
        $query = DB::table('journal_entry_lines as jel')
            ->join('journal_entries as je', 'jel.journal_entry_id', '=', 'je.id')
            ->join('chart_of_accounts as coa', 'jel.account_id', '=', 'coa.id')
            ->where('je.business_id', $businessId)
            ->where('je.status', 'Posted')
            ->where('je.posting_date', '<', $beforeDate)
            ->groupBy('jel.account_id', 'coa.account_name', 'coa.account_code', 'coa.account_type', 'coa.normal_balance')
            ->select(
                'jel.account_id',
                'coa.account_name',
                'coa.account_code',
                'coa.account_type',
                'coa.normal_balance',
                DB::raw('COALESCE(SUM(jel.debit_amount), 0) as total_debit'),
                DB::raw('COALESCE(SUM(jel.credit_amount), 0) as total_credit')
            )
            ->orderBy('coa.account_code');

        if (!empty($accountTypes)) {
            $query->whereIn('coa.account_type', $accountTypes);
        }

        return $query->get();
    }

    public function getAccountTransactions(string $businessId, string $accountId, string $startDate, string $endDate): Collection
    {
        return DB::table('journal_entry_lines as jel')
            ->join('journal_entries as je', 'jel.journal_entry_id', '=', 'je.id')
            ->where('je.business_id', $businessId)
            ->where('je.status', 'Posted')
            ->where('jel.account_id', $accountId)
            ->whereBetween('je.posting_date', [$startDate, $endDate])
            ->select(
                'je.id as journal_entry_id',
                'je.journal_number',
                'je.posting_date',
                'je.description as journal_description',
                'jel.id as line_id',
                'jel.description as line_description',
                'jel.debit_amount',
                'jel.credit_amount'
            )
            ->orderBy('je.posting_date')
            ->orderBy('je.created_at')
            ->get();
    }

    public function getAccountCumulativeBalance(string $businessId, string $accountId, string $beforeDate): array
    {
        $result = DB::table('journal_entry_lines as jel')
            ->join('journal_entries as je', 'jel.journal_entry_id', '=', 'je.id')
            ->where('je.business_id', $businessId)
            ->where('je.status', 'Posted')
            ->where('jel.account_id', $accountId)
            ->where('je.posting_date', '<', $beforeDate)
            ->select(
                DB::raw('COALESCE(SUM(jel.debit_amount), 0) as total_debit'),
                DB::raw('COALESCE(SUM(jel.credit_amount), 0) as total_credit')
            )
            ->first();

        return [
            'total_debit' => (float) ($result->total_debit ?? 0),
            'total_credit' => (float) ($result->total_credit ?? 0),
        ];
    }
}
