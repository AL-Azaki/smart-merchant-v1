<?php

namespace App\Domains\Sales\Repositories\Eloquent;

use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class SalesInvoiceEloquentRepository implements SalesInvoiceRepositoryInterface
{
    public function create(array $data): SalesInvoice
    {
        return DB::transaction(function () use ($data) {
            $items = $data['items'] ?? [];
            unset($data['items']);

            $invoice = SalesInvoice::create($data);

            if (!empty($items)) {
                $invoice->items()->createMany($items);
            }

            return $invoice->load('items');
        });
    }

    public function update(SalesInvoice $invoice, array $data): SalesInvoice
    {
        return DB::transaction(function () use ($invoice, $data) {
            $items = $data['items'] ?? null;
            unset($data['items']);

            $invoice->update($data);

            if ($items !== null) {
                $invoice->items()->delete();
                $invoice->items()->createMany($items);
            }

            return $invoice->load('items');
        });
    }

    public function findById(string $businessId, string $id): ?SalesInvoice
    {
        return SalesInvoice::where('business_id', $businessId)
            ->where('id', $id)
            ->with('items')
            ->first();
    }

    public function findByInvoiceNumber(string $businessId, string $invoiceNumber): ?SalesInvoice
    {
        return SalesInvoice::where('business_id', $businessId)
            ->where('invoice_number', $invoiceNumber)
            ->with('items')
            ->first();
    }

    public function getAll(string $businessId): Collection
    {
        return SalesInvoice::where('business_id', $businessId)
            ->with('items')
            ->get();
    }

    public function deleteDraft(SalesInvoice $invoice): bool
    {
        if ($invoice->status !== 'Draft') {
            return false;
        }

        return DB::transaction(function () use ($invoice) {
            $invoice->items()->delete();
            return $invoice->delete();
        });
    }

    public function existsByInvoiceNumber(string $businessId, string $invoiceNumber): bool
    {
        return SalesInvoice::where('business_id', $businessId)
            ->where('invoice_number', $invoiceNumber)
            ->exists();
    }
}
