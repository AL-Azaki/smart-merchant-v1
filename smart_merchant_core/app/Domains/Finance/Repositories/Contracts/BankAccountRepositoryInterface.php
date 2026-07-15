<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\DTOs\BankAccountListCriteriaDTO;
use App\Domains\Finance\DTOs\BankAccountSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface BankAccountRepositoryInterface
{
    public function create(array $data): BankAccount;
    
    public function update(BankAccount $bankAccount, array $data): BankAccount;
    
    public function delete(BankAccount $bankAccount): bool;
    
    public function findById(string $id): ?BankAccount;
    
    public function findByAccountNumber(string $businessId, string $accountNumber): ?BankAccount;

    public function findByIban(string $businessId, string $iban): ?BankAccount;
    
    public function paginate(BankAccountListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(BankAccountSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function isUsedInOperations(string $id): bool;

    public function removeDefaultForCurrency(string $businessId, string $currencyId): void;
}
