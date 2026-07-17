<?php

namespace App\Domains\AccountsPayable\Repositories\Eloquent;

use App\Domains\AccountsPayable\Models\SupplierPayable;
use App\Domains\AccountsPayable\Models\PayableEntry;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use Illuminate\Support\Collection;

class SupplierPayableEloquentRepository implements SupplierPayableRepositoryInterface
{
    public function create(array $data): SupplierPayable
    {
        return SupplierPayable::create($data);
    }

    public function update(string $id, array $data): SupplierPayable
    {
        $payable = SupplierPayable::findOrFail($id);
        $payable->update($data);
        return $payable;
    }

    public function findById(string $id): ?SupplierPayable
    {
        return SupplierPayable::find($id);
    }

    public function findBySupplier(string $businessId, string $supplierId): ?SupplierPayable
    {
        return SupplierPayable::where('business_id', $businessId)
            ->where('supplier_id', $supplierId)
            ->first();
    }

    public function list(array $filters = []): Collection
    {
        $query = SupplierPayable::query();

        if (isset($filters['business_id'])) {
            $query->where('business_id', $filters['business_id']);
        }
        if (isset($filters['supplier_id'])) {
            $query->where('supplier_id', $filters['supplier_id']);
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

    public function loadAggregate(string $id): ?SupplierPayable
    {
        return SupplierPayable::with(['entries', 'supplier', 'currency', 'creator'])->find($id);
    }

    public function addEntry(string $payableId, array $entryData): PayableEntry
    {
        $payable = SupplierPayable::findOrFail($payableId);
        return $payable->entries()->create($entryData);
    }
}
