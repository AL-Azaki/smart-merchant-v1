<?php

namespace App\Domains\FinancialReporting\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\FinancialReporting\Actions\GenerateTrialBalanceAction;
use App\Domains\FinancialReporting\Actions\GenerateGeneralLedgerReportAction;
use App\Domains\FinancialReporting\Actions\GenerateBalanceSheetAction;
use App\Domains\FinancialReporting\Actions\GenerateIncomeStatementAction;
use App\Domains\FinancialReporting\Actions\GenerateCashFlowStatementAction;
use App\Domains\FinancialReporting\Http\Requests\GeneratePeriodReportRequest;
use App\Domains\FinancialReporting\Http\Requests\GenerateGLReportRequest;
use App\Domains\FinancialReporting\Http\Requests\GenerateAsOfDateReportRequest;
use Illuminate\Http\JsonResponse;

class FinancialReportController extends Controller
{
    public function trialBalance(GeneratePeriodReportRequest $request, GenerateTrialBalanceAction $action): JsonResponse
    {
        $validated = $request->validated();
        $report = $action->execute($validated['business_id'], $validated['period_id']);
        return response()->json(['data' => $report]);
    }

    public function generalLedger(GenerateGLReportRequest $request, GenerateGeneralLedgerReportAction $action): JsonResponse
    {
        $validated = $request->validated();
        $report = $action->execute($validated['business_id'], $validated['period_id'], $validated['account_id']);
        return response()->json(['data' => $report]);
    }

    public function balanceSheet(GenerateAsOfDateReportRequest $request, GenerateBalanceSheetAction $action): JsonResponse
    {
        $validated = $request->validated();
        $report = $action->execute($validated['business_id'], $validated['as_of_date']);
        return response()->json(['data' => $report]);
    }

    public function incomeStatement(GeneratePeriodReportRequest $request, GenerateIncomeStatementAction $action): JsonResponse
    {
        $validated = $request->validated();
        $report = $action->execute($validated['business_id'], $validated['period_id']);
        return response()->json(['data' => $report]);
    }

    public function cashFlowStatement(GeneratePeriodReportRequest $request, GenerateCashFlowStatementAction $action): JsonResponse
    {
        $validated = $request->validated();
        $report = $action->execute($validated['business_id'], $validated['period_id']);
        return response()->json(['data' => $report]);
    }
}
