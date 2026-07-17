<?php

namespace App\Domains\AccountsReceivable\Repositories\Eloquent;

use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use App\Domains\AccountsReceivable\Models\ReceivableEntry;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use Illuminate\Support\Collection;

class CustomerReceivableEloquentRepository implements CustomerReceivableRepositoryInterface
{
    public function create(array $data): CustomerReceivable
    {
        return CustomerReceivable::create($data);
    }
    
    public function update(string $id, array $data): CustomerReceivable
    {
        $receivable = CustomerReceivable::findOrFail($id);
        $receivable->update($data);
        return $receivable;
    }
    
    public function findById(string $id): ?CustomerReceivable
    {
        return CustomerReceivable::find($id);
    }
    
    public function findByCustomer(string $businessId, string $customerId): ?CustomerReceivable
    {
        return CustomerReceivable::where('business_id', $businessId)
            ->where('customer_id', $customerId)
            ->first();
    }
    
    public function list(array $filters = []): Collection
    {
        $query = CustomerReceivable::query();

        if (isset($filters['business_id'])) {
            $query->where('business_id', $filters['business_id']);
        }
        if (isset($filters['customer_id'])) {
            $query->where('customer_id', $filters['customer_id']);
        }
        if (isset($filters['branch_id'])) {
            $query->where('branch_id', $filters['branch_id']);
        }
        if (isset($filters['currency_id'])) {
            $query->where('currency_id', $filters['currency_id']);
        }
        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        return $query->get();
    }
    
    public function loadAggregate(string $id): ?CustomerReceivable
    {
        return CustomerReceivable::with(['entries', 'customer', 'currency', 'creator'])->find($id);
    }
    
    public function addEntry(string $receivableId, array $entryData): ReceivableEntry
    {
        $receivable = CustomerReceivable::findOrFail($receivableId);
        return $receivable->entries()->create($entryData);
    }
}
