<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\DTOs\CashRegisterListCriteriaDTO;
use App\Domains\Finance\DTOs\CashRegisterSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface CashRegisterRepositoryInterface
{
    public function create(array $data): CashRegister;
    
    public function update(CashRegister $cashRegister, array $data): CashRegister;
    
    public function delete(CashRegister $cashRegister): bool;
    
    public function findById(string $id): ?CashRegister;
    
    public function findByName(string $businessId, string $registerName): ?CashRegister;
    
    public function paginate(CashRegisterListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(CashRegisterSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function isUsedInOperations(string $id): bool;
}
