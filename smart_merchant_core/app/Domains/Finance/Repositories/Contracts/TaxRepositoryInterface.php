<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\DTOs\TaxListCriteriaDTO;
use App\Domains\Finance\DTOs\TaxSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface TaxRepositoryInterface
{
    public function create(array $data): Tax;
    
    public function update(Tax $tax, array $data): Tax;
    
    public function delete(Tax $tax): bool;
    
    public function findById(string $id): ?Tax;
    
    public function findByName(string $businessId, string $taxName): ?Tax;
    
    public function paginate(TaxListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(TaxSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function isUsedInOperations(string $id): bool;
}
