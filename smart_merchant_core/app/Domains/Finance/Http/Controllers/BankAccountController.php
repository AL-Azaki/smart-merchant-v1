<?php

namespace App\Domains\Finance\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Actions\BankAccount\CreateBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\UpdateBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\FreezeBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\CloseBankAccountAction;
use App\Domains\Finance\Actions\BankAccount\CreateBankTransactionAction;
use App\Domains\Finance\Actions\BankAccount\ListBankAccountsAction;
use App\Domains\Finance\Actions\BankAccount\LoadBankAccountAggregateAction;
use App\Domains\Finance\Http\Requests\BankAccount\CreateBankAccountRequest;
use App\Domains\Finance\Http\Requests\BankAccount\UpdateBankAccountRequest;
use App\Domains\Finance\Http\Requests\BankAccount\FreezeBankAccountRequest;
use App\Domains\Finance\Http\Requests\BankAccount\CloseBankAccountRequest;
use App\Domains\Finance\Http\Requests\BankAccount\CreateBankTransactionRequest;
use App\Domains\Finance\Http\Resources\BankAccount\BankAccountResource;
use App\Domains\Finance\Http\Resources\BankAccount\BankAccountCollection;
use Illuminate\Http\Request;

class BankAccountController extends Controller
{
    public function index(Request $request, ListBankAccountsAction $action)
    {
        $this->authorize('viewAny', BankAccount::class);
        $accounts = $action->execute($request->all());
        return new BankAccountCollection($accounts);
    }

    public function show(BankAccount $bankAccount, LoadBankAccountAggregateAction $action)
    {
        $this->authorize('view', $bankAccount);
        $aggregate = $action->execute($bankAccount->id);
        return new BankAccountResource($aggregate);
    }

    public function store(CreateBankAccountRequest $request, CreateBankAccountAction $action)
    {
        $this->authorize('create', BankAccount::class);
        $account = $action->execute($request->validated());
        return new BankAccountResource($account);
    }

    public function update(UpdateBankAccountRequest $request, BankAccount $bankAccount, UpdateBankAccountAction $action)
    {
        $this->authorize('update', $bankAccount);
        $account = $action->execute($bankAccount->id, $request->validated());
        return new BankAccountResource($account);
    }

    public function freeze(FreezeBankAccountRequest $request, BankAccount $bankAccount, FreezeBankAccountAction $action)
    {
        $this->authorize('freeze', $bankAccount);
        $account = $action->execute($bankAccount->id, $request->validated());
        return new BankAccountResource($account);
    }

    public function close(CloseBankAccountRequest $request, BankAccount $bankAccount, CloseBankAccountAction $action)
    {
        $this->authorize('close', $bankAccount);
        $account = $action->execute($bankAccount->id, $request->validated());
        return new BankAccountResource($account);
    }

    public function addTransaction(CreateBankTransactionRequest $request, BankAccount $bankAccount, CreateBankTransactionAction $action, LoadBankAccountAggregateAction $loadAction)
    {
        $this->authorize('createTransaction', $bankAccount);
        $action->execute($bankAccount->id, $request->validated());

        $aggregate = $loadAction->execute($bankAccount->id);
        return new BankAccountResource($aggregate);
    }
}
