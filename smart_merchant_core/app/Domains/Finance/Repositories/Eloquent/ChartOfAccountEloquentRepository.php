<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use App\Domains\Finance\DTOs\ChartOfAccountListCriteriaDTO;
use App\Domains\Finance\DTOs\ChartOfAccountSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class ChartOfAccountEloquentRepository implements ChartOfAccountRepositoryInterface
{
    public function create(array $data): ChartOfAccount
    {
        return ChartOfAccount::create($data);
    }

    public function createMany(array $data): array
    {
        $records = [];
        foreach ($data as $item) {
            $records[] = ChartOfAccount::create($item);
        }
        return $records;
    }
    
    public function update(ChartOfAccount $account, array $data): ChartOfAccount
    {
        $account->update($data);
        return $account;
    }
    
    public function delete(ChartOfAccount $account): bool
    {
        return $account->delete();
    }
    
    public function findById(string $id): ?ChartOfAccount
    {
        return ChartOfAccount::with(['accountType', 'parent', 'currency'])->find($id);
    }
    
    public function findByCode(string $businessId, string $code): ?ChartOfAccount
    {
        return ChartOfAccount::where('business_id', $businessId)
            ->where('account_code', $code)
            ->first();
    }
    
    public function paginate(ChartOfAccountListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return ChartOfAccount::where('business_id', $criteria->businessId)
            ->with(['accountType', 'parent', 'currency'])
            ->orderBy('created_at', 'desc')
            ->paginate($criteria->perPage);
    }
    
    public function search(ChartOfAccountSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = ChartOfAccount::where('business_id', $criteria->businessId)
            ->with(['accountType', 'parent', 'currency']);
            
        if ($criteria->name) {
            $query->where('account_name', 'like', "%{$criteria->name}%");
        }
        
        if ($criteria->code) {
            $query->where('account_code', 'like', "%{$criteria->code}%");
        }
        
        if ($criteria->status !== null) {
            $query->where('is_active', $criteria->status);
        }
        
        if ($criteria->accountTypeId) {
            $query->where('account_type_id', $criteria->accountTypeId);
        }
        
        return $query->orderBy('created_at', 'desc')->paginate($criteria->perPage);
    }
    
    public function getTree(string $businessId): Collection
    {
        return ChartOfAccount::where('business_id', $businessId)
            ->with(['accountType', 'currency'])
            ->get();
    }
    
    public function countChildren(string $id): int
    {
        return ChartOfAccount::where('parent_account_id', $id)->count();
    }
    
    public function hasJournalLines(string $id): bool
    {
        $account = ChartOfAccount::find($id);
        if (!$account) return false;
        
        return $account->journalLines()->exists();
    }
    
    public function countRootAccounts(string $businessId): int
    {
        return ChartOfAccount::where('business_id', $businessId)
            ->whereNull('parent_account_id')
            ->count();
    }
}
