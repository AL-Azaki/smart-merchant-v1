<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Models\BankTransaction;
use Illuminate\Support\Collection;

interface BankAccountRepositoryInterface
{
    public function create(array $data): BankAccount;

    public function update(string $id, array $data): BankAccount;

    public function findById(string $id): ?BankAccount;

    public function findByAccountNumber(string $businessId, string $accountNumber): ?BankAccount;

    public function list(array $filters = []): Collection;

    public function loadAggregate(string $id): ?BankAccount;

    public function addTransaction(string $accountId, array $transactionData): BankTransaction;
}
