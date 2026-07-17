<?php

namespace App\Domains\AccountsPayable\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\AccountsPayable\Models\SupplierPayable;
use App\Domains\AccountsPayable\Actions\CreateSupplierPayableAction;
use App\Domains\AccountsPayable\Actions\UpdateSupplierPayableAction;
use App\Domains\AccountsPayable\Actions\RecordPayableEntryAction;
use App\Domains\AccountsPayable\Actions\ListSupplierPayablesAction;
use App\Domains\AccountsPayable\Actions\LoadSupplierPayableAggregateAction;
use App\Domains\AccountsPayable\Actions\GetSupplierStatementAction;
use App\Domains\AccountsPayable\Http\Requests\CreateSupplierPayableRequest;
use App\Domains\AccountsPayable\Http\Requests\UpdateSupplierPayableRequest;
use App\Domains\AccountsPayable\Http\Requests\RecordPayableEntryRequest;
use App\Domains\AccountsPayable\Http\Resources\SupplierPayableResource;
use App\Domains\AccountsPayable\Http\Resources\SupplierPayableCollection;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class SupplierPayableController extends Controller
{
    public function index(Request $request, ListSupplierPayablesAction $action)
    {
        $this->authorize('viewAny', SupplierPayable::class);
        $payables = $action->execute($request->all());
        return new SupplierPayableCollection($payables);
    }

    public function show(SupplierPayable $supplierPayable, LoadSupplierPayableAggregateAction $action)
    {
        $this->authorize('view', $supplierPayable);
        $aggregate = $action->execute($supplierPayable->id);
        return new SupplierPayableResource($aggregate);
    }

    public function store(CreateSupplierPayableRequest $request, CreateSupplierPayableAction $action)
    {
        $this->authorize('create', SupplierPayable::class);
        $payable = $action->execute($request->validated());
        return new SupplierPayableResource($payable);
    }

    public function update(UpdateSupplierPayableRequest $request, SupplierPayable $supplierPayable, UpdateSupplierPayableAction $action)
    {
        $this->authorize('update', $supplierPayable);
        $payable = $action->execute($supplierPayable->id, $request->validated());
        return new SupplierPayableResource($payable);
    }

    public function recordEntry(RecordPayableEntryRequest $request, SupplierPayable $supplierPayable, RecordPayableEntryAction $action, LoadSupplierPayableAggregateAction $loadAction)
    {
        $this->authorize('recordEntry', $supplierPayable);
        $action->execute($supplierPayable->id, $request->validated());

        $aggregate = $loadAction->execute($supplierPayable->id);
        return new SupplierPayableResource($aggregate);
    }

    public function statement(SupplierPayable $supplierPayable, GetSupplierStatementAction $action): JsonResponse
    {
        $this->authorize('view', $supplierPayable);
        $statement = $action->execute($supplierPayable->id);
        return response()->json($statement);
    }
}
