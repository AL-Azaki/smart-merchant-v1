<?php

namespace App\Domains\FinancialClosing\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Actions\CreateAccountingPeriodAction;
use App\Domains\FinancialClosing\Actions\UpdateAccountingPeriodAction;
use App\Domains\FinancialClosing\Actions\CloseAccountingPeriodAction;
use App\Domains\FinancialClosing\Actions\ReopenAccountingPeriodAction;
use App\Domains\FinancialClosing\Actions\ListAccountingPeriodsAction;
use App\Domains\FinancialClosing\Actions\LoadAccountingPeriodAggregateAction;
use App\Domains\FinancialClosing\Http\Requests\CreateAccountingPeriodRequest;
use App\Domains\FinancialClosing\Http\Requests\UpdateAccountingPeriodRequest;
use App\Domains\FinancialClosing\Http\Requests\CloseAccountingPeriodRequest;
use App\Domains\FinancialClosing\Http\Requests\ReopenAccountingPeriodRequest;
use App\Domains\FinancialClosing\Http\Resources\AccountingPeriodResource;
use App\Domains\FinancialClosing\Http\Resources\AccountingPeriodCollection;
use Illuminate\Http\Request;

class AccountingPeriodController extends Controller
{
    public function index(Request $request, ListAccountingPeriodsAction $action)
    {
        $this->authorize('viewAny', AccountingPeriod::class);
        $periods = $action->execute($request->all());
        return new AccountingPeriodCollection($periods);
    }

    public function show(AccountingPeriod $accountingPeriod, LoadAccountingPeriodAggregateAction $action)
    {
        $this->authorize('view', $accountingPeriod);
        $aggregate = $action->execute($accountingPeriod->id);
        return new AccountingPeriodResource($aggregate);
    }

    public function store(CreateAccountingPeriodRequest $request, CreateAccountingPeriodAction $action)
    {
        $this->authorize('create', AccountingPeriod::class);
        $period = $action->execute($request->validated());
        return new AccountingPeriodResource($period);
    }

    public function update(UpdateAccountingPeriodRequest $request, AccountingPeriod $accountingPeriod, UpdateAccountingPeriodAction $action)
    {
        $this->authorize('update', $accountingPeriod);
        $period = $action->execute($accountingPeriod->id, $request->validated());
        return new AccountingPeriodResource($period);
    }

    public function close(CloseAccountingPeriodRequest $request, AccountingPeriod $accountingPeriod, CloseAccountingPeriodAction $action)
    {
        $this->authorize('close', $accountingPeriod);
        $period = $action->execute($accountingPeriod->id, $request->validated()['user_id']);
        return new AccountingPeriodResource($period);
    }

    public function reopen(ReopenAccountingPeriodRequest $request, AccountingPeriod $accountingPeriod, ReopenAccountingPeriodAction $action)
    {
        $this->authorize('reopen', $accountingPeriod);
        $validated = $request->validated();
        $period = $action->execute($accountingPeriod->id, $validated['user_id'], $validated['reason']);
        return new AccountingPeriodResource($period);
    }
}
