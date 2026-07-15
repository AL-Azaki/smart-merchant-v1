<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\DTOs\FiscalYearListCriteriaDTO;
use App\Domains\Finance\DTOs\FiscalYearSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface FiscalYearRepositoryInterface
{
    public function create(array $data): FiscalYear;
    
    public function update(FiscalYear $fiscalYear, array $data): FiscalYear;
    
    public function delete(FiscalYear $fiscalYear): bool;
    
    public function findById(string $id): ?FiscalYear;
    
    public function findByCode(string $businessId, string $code): ?FiscalYear;
    
    public function findOverlapping(string $businessId, string $startDate, string $endDate, ?string $excludeId = null): ?FiscalYear;
    
    public function paginate(FiscalYearListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(FiscalYearSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function hasPeriods(string $id): bool;
    
    public function hasPostedJournalEntries(string $id): bool;
    
    public function getOpenPeriodsCount(string $id): int;
}
