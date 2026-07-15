<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\DTOs\PaymentTermListCriteriaDTO;
use App\Domains\Finance\DTOs\PaymentTermSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface PaymentTermRepositoryInterface
{
    public function create(array $data): PaymentTerm;
    
    public function update(PaymentTerm $paymentTerm, array $data): PaymentTerm;
    
    public function delete(PaymentTerm $paymentTerm): bool;
    
    public function findById(string $id): ?PaymentTerm;
    
    public function findByName(string $businessId, string $termName): ?PaymentTerm;
    
    public function paginate(PaymentTermListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(PaymentTermSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function isUsedInOperations(string $id): bool;
}
