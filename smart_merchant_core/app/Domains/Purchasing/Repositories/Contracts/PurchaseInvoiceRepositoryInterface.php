<?php

namespace App\Domains\Purchasing\Repositories\Contracts;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use Illuminate\Support\Collection;

interface PurchaseInvoiceRepositoryInterface
{
    public function create(array $data): PurchaseInvoice;
    public function update(PurchaseInvoice $invoice, array $data): PurchaseInvoice;
    public function delete(PurchaseInvoice $invoice): bool;
    public function findById(string $businessId, string $id): ?PurchaseInvoice;
    public function findByInvoiceNumber(string $businessId, string $invoiceNumber): ?PurchaseInvoice;
    public function getAll(string $businessId): Collection;
    public function exists(string $businessId, string $id): bool;
}
