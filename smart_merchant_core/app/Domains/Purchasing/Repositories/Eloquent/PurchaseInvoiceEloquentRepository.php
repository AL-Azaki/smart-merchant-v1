<?php

namespace App\Domains\Purchasing\Repositories\Eloquent;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Repositories\Contracts\PurchaseInvoiceRepositoryInterface;
use Illuminate\Support\Collection;

class PurchaseInvoiceEloquentRepository implements PurchaseInvoiceRepositoryInterface
{
    public function create(array $data): PurchaseInvoice
    {
        $invoice = PurchaseInvoice::create($data);
        
        if (isset($data['items']) && is_array($data['items'])) {
            $invoice->items()->createMany($data['items']);
        }
        
        return $invoice->load('items');
    }

    public function update(PurchaseInvoice $invoice, array $data): PurchaseInvoice
    {
        $invoice->update($data);
        
        if (isset($data['items']) && is_array($data['items'])) {
            $invoice->items()->delete();
            $invoice->items()->createMany($data['items']);
        }
        
        return $invoice->load('items');
    }

    public function delete(PurchaseInvoice $invoice): bool
    {
        return $invoice->delete();
    }

    public function findById(string $businessId, string $id): ?PurchaseInvoice
    {
        return PurchaseInvoice::with('items')
            ->where('business_id', $businessId)
            ->find($id);
    }

    public function findByInvoiceNumber(string $businessId, string $invoiceNumber): ?PurchaseInvoice
    {
        return PurchaseInvoice::with('items')
            ->where('business_id', $businessId)
            ->where('invoice_number', $invoiceNumber)
            ->first();
    }

    public function getAll(string $businessId): Collection
    {
        return PurchaseInvoice::with('items')
            ->where('business_id', $businessId)
            ->get();
    }

    public function exists(string $businessId, string $id): bool
    {
        return PurchaseInvoice::where('business_id', $businessId)
            ->where('id', $id)
            ->exists();
    }
}
