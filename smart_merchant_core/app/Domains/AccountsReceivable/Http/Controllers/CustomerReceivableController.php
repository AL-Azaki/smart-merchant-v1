<?php

namespace App\Domains\AccountsReceivable\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use App\Domains\AccountsReceivable\Actions\CreateCustomerReceivableAction;
use App\Domains\AccountsReceivable\Actions\UpdateCustomerReceivableAction;
use App\Domains\AccountsReceivable\Actions\RecordReceivableEntryAction;
use App\Domains\AccountsReceivable\Actions\ListCustomerReceivablesAction;
use App\Domains\AccountsReceivable\Actions\LoadCustomerReceivableAggregateAction;
use App\Domains\AccountsReceivable\Actions\GetCustomerStatementAction;
use App\Domains\AccountsReceivable\Http\Requests\CreateCustomerReceivableRequest;
use App\Domains\AccountsReceivable\Http\Requests\UpdateCustomerReceivableRequest;
use App\Domains\AccountsReceivable\Http\Requests\RecordReceivableEntryRequest;
use App\Domains\AccountsReceivable\Http\Resources\CustomerReceivableResource;
use App\Domains\AccountsReceivable\Http\Resources\CustomerReceivableCollection;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CustomerReceivableController extends Controller
{
    public function index(Request $request, ListCustomerReceivablesAction $action)
    {
        $this->authorize('viewAny', CustomerReceivable::class);
        $receivables = $action->execute($request->all());
        return new CustomerReceivableCollection($receivables);
    }

    public function show(CustomerReceivable $customerReceivable, LoadCustomerReceivableAggregateAction $action)
    {
        $this->authorize('view', $customerReceivable);
        $aggregate = $action->execute($customerReceivable->id);
        return new CustomerReceivableResource($aggregate);
    }

    public function store(CreateCustomerReceivableRequest $request, CreateCustomerReceivableAction $action)
    {
        $this->authorize('create', CustomerReceivable::class);
        $receivable = $action->execute($request->validated());
        return new CustomerReceivableResource($receivable);
    }

    public function update(UpdateCustomerReceivableRequest $request, CustomerReceivable $customerReceivable, UpdateCustomerReceivableAction $action)
    {
        $this->authorize('update', $customerReceivable);
        $receivable = $action->execute($customerReceivable->id, $request->validated());
        return new CustomerReceivableResource($receivable);
    }

    public function recordEntry(RecordReceivableEntryRequest $request, CustomerReceivable $customerReceivable, RecordReceivableEntryAction $action, LoadCustomerReceivableAggregateAction $loadAction)
    {
        $this->authorize('recordEntry', $customerReceivable);
        $action->execute($customerReceivable->id, $request->validated());
        
        $aggregate = $loadAction->execute($customerReceivable->id);
        return new CustomerReceivableResource($aggregate);
    }

    public function statement(CustomerReceivable $customerReceivable, GetCustomerStatementAction $action): JsonResponse
    {
        $this->authorize('view', $customerReceivable);
        $statement = $action->execute($customerReceivable->id);
        return response()->json($statement);
    }
}
