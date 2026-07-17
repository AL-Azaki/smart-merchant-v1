<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\CashRegister;
use Illuminate\Support\Collection;

interface CashRegisterRepositoryInterface
{
    public function create(array $data): CashRegister;
    
    public function update(string $id, array $data): CashRegister;
    
    public function findById(string $id): ?CashRegister;
    
    public function findByCode(string $businessId, string $code): ?CashRegister;
    
    public function list(array $filters = []): Collection;
    
    public function loadAggregate(string $id): ?CashRegister;
    
    public function addTransaction(string $registerId, array $transactionData): \App\Domains\Finance\Models\CashTransaction;
}
