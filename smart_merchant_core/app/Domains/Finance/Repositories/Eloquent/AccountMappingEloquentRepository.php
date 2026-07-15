<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Repositories\Contracts\AccountMappingRepositoryInterface;
use Illuminate\Support\Collection;

class AccountMappingEloquentRepository implements AccountMappingRepositoryInterface
{
    public function findByMappingType(string $businessId, string $mappingType): ?AccountMapping
    {
        return AccountMapping::where('business_id', $businessId)
            ->where('mapping_type', $mappingType)
            ->first();
    }
    
    public function findByBusiness(string $businessId): Collection
    {
        return AccountMapping::where('business_id', $businessId)->get();
    }
    
    public function checkMappingExists(string $businessId, string $mappingType): bool
    {
        return AccountMapping::where('business_id', $businessId)
            ->where('mapping_type', $mappingType)
            ->exists();
    }
    
    public function create(array $data): AccountMapping
    {
        return AccountMapping::create($data);
    }
    
    public function update(AccountMapping $accountMapping, array $data): AccountMapping
    {
        $accountMapping->update($data);
        return $accountMapping;
    }
    
    public function delete(AccountMapping $accountMapping): bool
    {
        return $accountMapping->delete();
    }
    
    public function getAll(string $businessId): Collection
    {
        return AccountMapping::where('business_id', $businessId)->get();
    }
}
