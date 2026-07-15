<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use App\Domains\Finance\DTOs\FiscalPeriodListCriteriaDTO;
use App\Domains\Finance\DTOs\FiscalPeriodSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class FiscalPeriodEloquentRepository implements FiscalPeriodRepositoryInterface
{
    public function create(array $data): FiscalPeriod
    {
        return FiscalPeriod::create($data);
    }
    
    public function update(FiscalPeriod $fiscalPeriod, array $data): FiscalPeriod
    {
        $fiscalPeriod->update($data);
        return $fiscalPeriod;
    }
    
    public function delete(FiscalPeriod $fiscalPeriod): bool
    {
        return $fiscalPeriod->delete();
    }
    
    public function findById(string $id): ?FiscalPeriod
    {
        return FiscalPeriod::with('fiscalYear')->find($id);
    }
    
    public function findByNumber(string $fiscalYearId, int $periodNumber): ?FiscalPeriod
    {
        return FiscalPeriod::where('fiscal_year_id', $fiscalYearId)
            ->where('period_number', $periodNumber)
            ->first();
    }
    
    public function findOverlapping(string $fiscalYearId, string $startDate, string $endDate, ?string $excludeId = null): ?FiscalPeriod
    {
        $query = FiscalPeriod::where('fiscal_year_id', $fiscalYearId)
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
    
    public function paginate(FiscalPeriodListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return FiscalPeriod::where('fiscal_year_id', $criteria->fiscalYearId)
            ->whereHas('fiscalYear', function ($q) use ($criteria) {
                $q->where('business_id', $criteria->businessId);
            })
            ->orderBy('period_number', 'asc')
            ->paginate($criteria->perPage);
    }
    
    public function search(FiscalPeriodSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = FiscalPeriod::whereHas('fiscalYear', function ($q) use ($criteria) {
            $q->where('business_id', $criteria->businessId);
        });
            
        if ($criteria->fiscalYearId) {
            $query->where('fiscal_year_id', $criteria->fiscalYearId);
        }

        if ($criteria->name) {
            $query->where('period_name', 'like', "%{$criteria->name}%");
        }
        
        if ($criteria->status) {
            $query->where('status', $criteria->status);
        }
        
        return $query->orderBy('start_date', 'asc')->paginate($criteria->perPage);
    }
    
    public function hasDraftJournalEntries(string $id): bool
    {
        $period = FiscalPeriod::find($id);
        if (!$period) return false;
        
        return $period->journalEntries()->where('status', 'Draft')->exists();
    }
    
    public function hasPostedJournalEntries(string $id): bool
    {
        $period = FiscalPeriod::find($id);
        if (!$period) return false;
        
        return $period->journalEntries()->where('status', 'Posted')->exists();
    }
    
    public function hasJournalEntriesOutsideDates(string $id, string $startDate, string $endDate): bool
    {
        $period = FiscalPeriod::find($id);
        if (!$period) return false;
        
        return $period->journalEntries()
            ->where(function ($q) use ($startDate, $endDate) {
                $q->where('journal_date', '<', $startDate)
                  ->orWhere('journal_date', '>', $endDate);
            })->exists();
    }
}
