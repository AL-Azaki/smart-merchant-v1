<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use App\Domains\Finance\DTOs\PaymentTermListCriteriaDTO;
use App\Domains\Finance\DTOs\PaymentTermSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class PaymentTermEloquentRepository implements PaymentTermRepositoryInterface
{
    public function create(array $data): PaymentTerm
    {
        return PaymentTerm::create($data);
    }
    
    public function update(PaymentTerm $paymentTerm, array $data): PaymentTerm
    {
        $paymentTerm->update($data);
        return $paymentTerm;
    }
    
    public function delete(PaymentTerm $paymentTerm): bool
    {
        return $paymentTerm->delete();
    }
    
    public function findById(string $id): ?PaymentTerm
    {
        return PaymentTerm::find($id);
    }
    
    public function findByName(string $businessId, string $termName): ?PaymentTerm
    {
        return PaymentTerm::where('business_id', $businessId)
            ->where('term_name', $termName)
            ->first();
    }
    
    public function paginate(PaymentTermListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return PaymentTerm::where('business_id', $criteria->businessId)
            ->orderBy('term_name')
            ->paginate($criteria->perPage);
    }
    
    public function search(PaymentTermSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = PaymentTerm::where('business_id', $criteria->businessId);
            
        if ($criteria->termName) {
            $query->where('term_name', 'like', '%' . $criteria->termName . '%');
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }
        
        return $query->orderBy('term_name')->paginate($criteria->perPage);
    }
    
    public function isUsedInOperations(string $id): bool
    {
        // For V1, check if payment term is linked to customers, suppliers, or invoices
        $usedInCustomers = DB::table('customers')->where('payment_term_id', $id)->exists();
        $usedInSuppliers = DB::table('suppliers')->where('payment_term_id', $id)->exists();
        $usedInSalesInvoices = DB::table('sales_invoices')->where('payment_term_id', $id)->exists();
        $usedInPurchaseInvoices = DB::table('purchase_invoices')->where('payment_term_id', $id)->exists();
        
        return $usedInCustomers || $usedInSuppliers || $usedInSalesInvoices || $usedInPurchaseInvoices;
    }
}
