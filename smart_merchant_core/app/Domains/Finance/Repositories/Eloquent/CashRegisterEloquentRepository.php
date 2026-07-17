<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Support\Collection;

class CashRegisterEloquentRepository implements CashRegisterRepositoryInterface
{
    public function create(array $data): CashRegister
    {
        return CashRegister::create($data);
    }
    
    public function update(string $id, array $data): CashRegister
    {
        $register = CashRegister::findOrFail($id);
        $register->update($data);
        return $register;
    }
    
    public function findById(string $id): ?CashRegister
    {
        return CashRegister::find($id);
    }
    
    public function findByCode(string $businessId, string $code): ?CashRegister
    {
        // Using register_name as the unique identifier/code per business
        return CashRegister::where('business_id', $businessId)
            ->where('register_name', $code)
            ->first();
    }
    
    public function list(array $filters = []): Collection
    {
        $query = CashRegister::query();

        if (isset($filters['business_id'])) {
            $query->where('business_id', $filters['business_id']);
        }

        if (isset($filters['branch_id'])) {
            $query->where('branch_id', $filters['branch_id']);
        }

        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        return $query->get();
    }
    
    public function loadAggregate(string $id): ?CashRegister
    {
        return CashRegister::with(['transactions', 'currency', 'creator', 'updater'])->find($id);
    }

    public function addTransaction(string $registerId, array $transactionData): \App\Domains\Finance\Models\CashTransaction
    {
        $register = CashRegister::findOrFail($registerId);
        return $register->transactions()->create($transactionData);
    }
}
