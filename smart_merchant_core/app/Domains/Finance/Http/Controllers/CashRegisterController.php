<?php

namespace App\Domains\Finance\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Actions\CashRegister\CreateCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\UpdateCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\OpenCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\CloseCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\CreateCashTransactionAction;
use App\Domains\Finance\Actions\CashRegister\GetCashRegisterAction;
use App\Domains\Finance\Actions\CashRegister\ListCashRegistersAction;
use App\Domains\Finance\Actions\CashRegister\LoadCashRegisterAggregateAction;
use App\Domains\Finance\Http\Requests\CashRegister\CreateCashRegisterRequest;
use App\Domains\Finance\Http\Requests\CashRegister\UpdateCashRegisterRequest;
use App\Domains\Finance\Http\Requests\CashRegister\OpenCashRegisterRequest;
use App\Domains\Finance\Http\Requests\CashRegister\CloseCashRegisterRequest;
use App\Domains\Finance\Http\Requests\CashRegister\CreateCashTransactionRequest;
use App\Domains\Finance\Http\Resources\CashRegister\CashRegisterResource;
use App\Domains\Finance\Http\Resources\CashRegister\CashRegisterCollection;
use Illuminate\Http\Request;

class CashRegisterController extends Controller
{
    public function index(Request $request, ListCashRegistersAction $action)
    {
        $this->authorize('viewAny', CashRegister::class);
        $registers = $action->execute($request->all());
        return new CashRegisterCollection($registers);
    }

    public function show(CashRegister $cashRegister, LoadCashRegisterAggregateAction $action)
    {
        $this->authorize('view', $cashRegister);
        $aggregate = $action->execute($cashRegister->id);
        return new CashRegisterResource($aggregate);
    }

    public function store(CreateCashRegisterRequest $request, CreateCashRegisterAction $action)
    {
        $this->authorize('create', CashRegister::class);
        $register = $action->execute($request->validated());
        return new CashRegisterResource($register);
    }

    public function update(UpdateCashRegisterRequest $request, CashRegister $cashRegister, UpdateCashRegisterAction $action)
    {
        $this->authorize('update', $cashRegister);
        $register = $action->execute($cashRegister->id, $request->validated());
        return new CashRegisterResource($register);
    }

    public function open(OpenCashRegisterRequest $request, CashRegister $cashRegister, OpenCashRegisterAction $action)
    {
        $this->authorize('open', $cashRegister);
        $register = $action->execute($cashRegister->id, $request->validated());
        return new CashRegisterResource($register);
    }

    public function close(CloseCashRegisterRequest $request, CashRegister $cashRegister, CloseCashRegisterAction $action)
    {
        $this->authorize('close', $cashRegister);
        $register = $action->execute($cashRegister->id, $request->validated());
        return new CashRegisterResource($register);
    }

    public function addTransaction(CreateCashTransactionRequest $request, CashRegister $cashRegister, CreateCashTransactionAction $action, LoadCashRegisterAggregateAction $loadAction)
    {
        $this->authorize('createTransaction', $cashRegister);
        $action->execute($cashRegister->id, $request->validated());
        
        $aggregate = $loadAction->execute($cashRegister->id);
        return new CashRegisterResource($aggregate);
    }
}
