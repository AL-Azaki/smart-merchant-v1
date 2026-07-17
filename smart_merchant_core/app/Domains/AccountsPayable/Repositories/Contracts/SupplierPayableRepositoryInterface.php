<?php

namespace App\Domains\AccountsPayable\Repositories\Contracts;

use App\Domains\AccountsPayable\Models\SupplierPayable;
use App\Domains\AccountsPayable\Models\PayableEntry;
use Illuminate\Support\Collection;

interface SupplierPayableRepositoryInterface
{
    public function create(array $data): SupplierPayable;

    public function update(string $id, array $data): SupplierPayable;

    public function findById(string $id): ?SupplierPayable;

    public function findBySupplier(string $businessId, string $supplierId): ?SupplierPayable;

    public function list(array $filters = []): Collection;

    public function loadAggregate(string $id): ?SupplierPayable;

    public function addEntry(string $payableId, array $entryData): PayableEntry;
}
