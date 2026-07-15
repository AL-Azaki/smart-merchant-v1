<?php

namespace App\Domains\Sales\Repositories\Contracts;

use App\Domains\Sales\Models\SalesInvoice;
use Illuminate\Support\Collection;

interface SalesInvoiceRepositoryInterface
{
    public function create(array $data): SalesInvoice;
    
    public function update(SalesInvoice $invoice, array $data): SalesInvoice;
    
    public function findById(string $businessId, string $id): ?SalesInvoice;
    
    public function findByInvoiceNumber(string $businessId, string $invoiceNumber): ?SalesInvoice;
    
    public function getAll(string $businessId): Collection;
    
    public function deleteDraft(SalesInvoice $invoice): bool;
    
    public function existsByInvoiceNumber(string $businessId, string $invoiceNumber): bool;
}
