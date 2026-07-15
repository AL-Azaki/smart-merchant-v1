<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use App\Domains\Finance\DTOs\FiscalYearListCriteriaDTO;
use App\Domains\Finance\DTOs\FiscalYearSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class FiscalYearEloquentRepository implements FiscalYearRepositoryInterface
{
    public function create(array $data): FiscalYear
    {
        return FiscalYear::create($data);
    }
    
    public function update(FiscalYear $fiscalYear, array $data): FiscalYear
    {
        $fiscalYear->update($data);
        return $fiscalYear;
    }
    
    public function delete(FiscalYear $fiscalYear): bool
    {
        return $fiscalYear->delete();
    }
    
    public function findById(string $id): ?FiscalYear
    {
        return FiscalYear::find($id);
    }
    
    public function findByCode(string $businessId, string $code): ?FiscalYear
    {
        return FiscalYear::where('business_id', $businessId)
            ->where('fiscal_year_code', $code)
            ->first();
    }
    
    public function findOverlapping(string $businessId, string $startDate, string $endDate, ?string $excludeId = null): ?FiscalYear
    {
        $query = FiscalYear::where('business_id', $businessId)
            ->where(function ($q) use ($startDate, $endDate) {
                $q->whereBetween('start_date', [$startDate, $endDate])
                  ->orWhereBetween('end_date', [$startDate, $endDate])
                  ->orWhere(function ($q2) use ($startDate, $endDate) {
                      $q2->where('start_date', '<=', $startDate)
                         ->where('end_date', '>=', $endDate);
                  });
            });

        if ($excludeId) {
            $query->where('id', '!=', $excludeId);
        }

        return $query->first();
    }
    
    public function paginate(FiscalYearListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return FiscalYear::where('business_id', $criteria->businessId)
            ->orderBy('start_date', 'desc')
            ->paginate($criteria->perPage);
    }
    
    public function search(FiscalYearSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = FiscalYear::where('business_id', $criteria->businessId);
            
        if ($criteria->code) {
            $query->where('fiscal_year_code', 'like', "%{$criteria->code}%");
        }

        if ($criteria->name) {
            $query->where('fiscal_year_name', 'like', "%{$criteria->name}%");
        }
        
        if ($criteria->status) {
            $query->where('status', $criteria->status);
        }
        
        return $query->orderBy('start_date', 'desc')->paginate($criteria->perPage);
    }
    
    public function hasPeriods(string $id): bool
    {
        $year = FiscalYear::find($id);
        if (!$year) return false;
        
        return $year->periods()->exists();
    }
    
    public function hasPostedJournalEntries(string $id): bool
    {
        $year = FiscalYear::find($id);
        if (!$year) return false;
        
        return $year->journalEntries()->where('status', 'Posted')->exists();
    }
    
    public function getOpenPeriodsCount(string $id): int
    {
        $year = FiscalYear::find($id);
        if (!$year) return 0;
        
        return $year->periods()->where('status', 'Open')->count();
    }
}
