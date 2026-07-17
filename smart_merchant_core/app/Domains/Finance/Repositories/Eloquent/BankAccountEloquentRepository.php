<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Models\BankTransaction;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Illuminate\Support\Collection;

class BankAccountEloquentRepository implements BankAccountRepositoryInterface
{
    public function create(array $data): BankAccount
    {
        return BankAccount::create($data);
    }

    public function update(string $id, array $data): BankAccount
    {
        $account = BankAccount::findOrFail($id);
        $account->update($data);
        return $account;
    }

    public function findById(string $id): ?BankAccount
    {
        return BankAccount::find($id);
    }

    public function findByAccountNumber(string $businessId, string $accountNumber): ?BankAccount
    {
        return BankAccount::where('business_id', $businessId)
            ->where('account_number', $accountNumber)
            ->first();
    }

    public function list(array $filters = []): Collection
    {
        $query = BankAccount::query();

        if (isset($filters['business_id'])) {
            $query->where('business_id', $filters['business_id']);
        }

        if (isset($filters['branch_id'])) {
            $query->where('branch_id', $filters['branch_id']);
        }

        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['currency_id'])) {
            $query->where('currency_id', $filters['currency_id']);
        }

        return $query->get();
    }

    public function loadAggregate(string $id): ?BankAccount
    {
        return BankAccount::with(['transactions', 'currency', 'creator', 'updater'])->find($id);
    }

    public function addTransaction(string $accountId, array $transactionData): BankTransaction
    {
        $account = BankAccount::findOrFail($accountId);
        return $account->transactions()->create($transactionData);
    }
}
