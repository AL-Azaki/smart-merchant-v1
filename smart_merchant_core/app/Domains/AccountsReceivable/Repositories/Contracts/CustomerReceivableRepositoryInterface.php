<?php

namespace App\Domains\AccountsReceivable\Repositories\Contracts;

use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use App\Domains\AccountsReceivable\Models\ReceivableEntry;
use Illuminate\Support\Collection;

interface CustomerReceivableRepositoryInterface
{
    public function create(array $data): CustomerReceivable;
    
    public function update(string $id, array $data): CustomerReceivable;
    
    public function findById(string $id): ?CustomerReceivable;
    
    public function findByCustomer(string $businessId, string $customerId): ?CustomerReceivable;
    
    public function list(array $filters = []): Collection;
    
    public function loadAggregate(string $id): ?CustomerReceivable;
    
    public function addEntry(string $receivableId, array $entryData): ReceivableEntry;
}
