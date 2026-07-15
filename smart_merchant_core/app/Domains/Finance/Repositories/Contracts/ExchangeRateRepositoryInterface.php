<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\ExchangeRate;
use App\Domains\Finance\DTOs\ExchangeRateListCriteriaDTO;
use App\Domains\Finance\DTOs\ExchangeRateSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface ExchangeRateRepositoryInterface
{
    public function create(array $data): ExchangeRate;
    
    public function update(ExchangeRate $exchangeRate, array $data): ExchangeRate;
    
    public function delete(ExchangeRate $exchangeRate): bool;
    
    public function findById(string $id): ?ExchangeRate;
    
    public function findExactRate(string $businessId, string $sourceCurrencyId, string $targetCurrencyId, string $effectiveDate): ?ExchangeRate;
    
    public function paginate(ExchangeRateListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(ExchangeRateSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function isUsedInJournalEntries(string $id): bool;
}
