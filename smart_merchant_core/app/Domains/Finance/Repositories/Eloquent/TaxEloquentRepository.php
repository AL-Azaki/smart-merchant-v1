<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\Tax;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use App\Domains\Finance\DTOs\TaxListCriteriaDTO;
use App\Domains\Finance\DTOs\TaxSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class TaxEloquentRepository implements TaxRepositoryInterface
{
    public function create(array $data): Tax
    {
        return Tax::create($data);
    }
    
    public function update(Tax $tax, array $data): Tax
    {
        $tax->update($data);
        return $tax;
    }
    
    public function delete(Tax $tax): bool
    {
        return $tax->delete();
    }
    
    public function findById(string $id): ?Tax
    {
        return Tax::find($id);
    }
    
    public function findByName(string $businessId, string $taxName): ?Tax
    {
        return Tax::where('business_id', $businessId)
            ->where('tax_name', $taxName)
            ->first();
    }
    
    public function paginate(TaxListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Tax::where('business_id', $criteria->businessId)
            ->orderBy('tax_name')
            ->paginate($criteria->perPage);
    }
    
    public function search(TaxSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Tax::where('business_id', $criteria->businessId);
            
        if ($criteria->taxName) {
            $query->where('tax_name', 'like', '%' . $criteria->taxName . '%');
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }
        
        return $query->orderBy('tax_name')->paginate($criteria->perPage);
    }
    
    public function isUsedInOperations(string $id): bool
    {
        // For V1, check if tax is linked to products via product_taxes
        $usedInProducts = DB::table('product_taxes')->where('tax_id', $id)->exists();
        
        // In the future or if there are other operational tables holding tax_id, we would check them here.
        // For now, product_taxes is the main relation.
        return $usedInProducts;
    }
}
