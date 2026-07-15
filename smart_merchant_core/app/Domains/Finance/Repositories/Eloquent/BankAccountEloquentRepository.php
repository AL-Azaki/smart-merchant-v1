<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use App\Domains\Finance\DTOs\BankAccountListCriteriaDTO;
use App\Domains\Finance\DTOs\BankAccountSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class BankAccountEloquentRepository implements BankAccountRepositoryInterface
{
    public function create(array $data): BankAccount
    {
        return BankAccount::create($data);
    }
    
    public function update(BankAccount $bankAccount, array $data): BankAccount
    {
        $bankAccount->update($data);
        return $bankAccount;
    }
    
    public function delete(BankAccount $bankAccount): bool
    {
        return $bankAccount->delete();
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

    public function findByIban(string $businessId, string $iban): ?BankAccount
    {
        return BankAccount::where('business_id', $businessId)
            ->where('iban', $iban)
            ->first();
    }
    
    public function paginate(BankAccountListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return BankAccount::where('business_id', $criteria->businessId)
            ->orderBy('bank_name')
            ->paginate($criteria->perPage);
    }
    
    public function search(BankAccountSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = BankAccount::where('business_id', $criteria->businessId);
            
        if ($criteria->bankName) {
            $query->where('bank_name', 'like', '%' . $criteria->bankName . '%');
        }

        if ($criteria->accountNumber) {
            $query->where('account_number', 'like', '%' . $criteria->accountNumber . '%');
        }

        if ($criteria->currencyId) {
            $query->where('currency_id', $criteria->currencyId);
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }
        
        return $query->orderBy('bank_name')->paginate($criteria->perPage);
    }
    
    public function isUsedInOperations(string $id): bool
    {
        // Check if bank account is linked to payments or other operational tables
        $usedInPayments = DB::table('payments')->where('bank_account_id', $id)->exists();
        
        // Check journal entries (though usually mapped via COA, bank_account_id could be stored as reference)
        // For V1, payments table is the direct usage
        return $usedInPayments;
    }

    public function removeDefaultForCurrency(string $businessId, string $currencyId): void
    {
        BankAccount::where('business_id', $businessId)
            ->where('currency_id', $currencyId)
            ->where('is_default', true)
            ->update(['is_default' => false]);
    }
}
