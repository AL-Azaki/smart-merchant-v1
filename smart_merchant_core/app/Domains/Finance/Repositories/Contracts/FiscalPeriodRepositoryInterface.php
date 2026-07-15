<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\DTOs\FiscalPeriodListCriteriaDTO;
use App\Domains\Finance\DTOs\FiscalPeriodSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface FiscalPeriodRepositoryInterface
{
    public function create(array $data): FiscalPeriod;
    
    public function update(FiscalPeriod $fiscalPeriod, array $data): FiscalPeriod;
    
    public function delete(FiscalPeriod $fiscalPeriod): bool;
    
    public function findById(string $id): ?FiscalPeriod;
    
    public function findByNumber(string $fiscalYearId, int $periodNumber): ?FiscalPeriod;
    
    public function findOverlapping(string $fiscalYearId, string $startDate, string $endDate, ?string $excludeId = null): ?FiscalPeriod;
    
    public function paginate(FiscalPeriodListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(FiscalPeriodSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function hasDraftJournalEntries(string $id): bool;
    
    public function hasPostedJournalEntries(string $id): bool;
    
    public function hasJournalEntriesOutsideDates(string $id, string $startDate, string $endDate): bool;
}
