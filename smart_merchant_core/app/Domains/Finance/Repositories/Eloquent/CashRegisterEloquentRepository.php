<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\DTOs\CashRegisterListCriteriaDTO;
use App\Domains\Finance\DTOs\CashRegisterSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class CashRegisterEloquentRepository implements CashRegisterRepositoryInterface
{
    public function create(array $data): CashRegister
    {
        return CashRegister::create($data);
    }
    
    public function update(CashRegister $cashRegister, array $data): CashRegister
    {
        $cashRegister->update($data);
        return $cashRegister;
    }
    
    public function delete(CashRegister $cashRegister): bool
    {
        return $cashRegister->delete();
    }
    
    public function findById(string $id): ?CashRegister
    {
        return CashRegister::find($id);
    }
    
    public function findByName(string $businessId, string $registerName): ?CashRegister
    {
        return CashRegister::where('business_id', $businessId)
            ->where('register_name', $registerName)
            ->first();
    }
    
    public function paginate(CashRegisterListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return CashRegister::where('business_id', $criteria->businessId)
            ->orderBy('register_name')
            ->paginate($criteria->perPage);
    }
    
    public function search(CashRegisterSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = CashRegister::where('business_id', $criteria->businessId);
            
        if ($criteria->registerName) {
            $query->where('register_name', 'like', '%' . $criteria->registerName . '%');
        }

        if ($criteria->branchId) {
            $query->where('branch_id', $criteria->branchId);
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }
        
        return $query->orderBy('register_name')->paginate($criteria->perPage);
    }
    
    public function isUsedInOperations(string $id): bool
    {
        // Check if cash register is linked to payments or other operational tables
        $usedInPayments = DB::table('payments')->where('cash_register_id', $id)->exists();
        // Since we don't have the full V1 implementation yet for all possible usages, we check the most obvious one.
        
        return $usedInPayments;
    }
}
