<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\AccountMapping;
use Illuminate\Support\Collection;

interface AccountMappingRepositoryInterface
{
    public function findByMappingType(string $businessId, string $mappingType): ?AccountMapping;
    
    public function findByBusiness(string $businessId): Collection;
    
    public function checkMappingExists(string $businessId, string $mappingType): bool;
    
    public function create(array $data): AccountMapping;
    
    public function update(AccountMapping $accountMapping, array $data): AccountMapping;
    
    public function delete(AccountMapping $accountMapping): bool;
    
    public function getAll(string $businessId): Collection;
}
