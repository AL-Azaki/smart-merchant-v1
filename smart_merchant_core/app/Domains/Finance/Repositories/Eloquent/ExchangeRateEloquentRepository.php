<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\ExchangeRate;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use App\Domains\Finance\DTOs\ExchangeRateListCriteriaDTO;
use App\Domains\Finance\DTOs\ExchangeRateSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ExchangeRateEloquentRepository implements ExchangeRateRepositoryInterface
{
    public function create(array $data): ExchangeRate
    {
        return ExchangeRate::create($data);
    }
    
    public function update(ExchangeRate $exchangeRate, array $data): ExchangeRate
    {
        $exchangeRate->update($data);
        return $exchangeRate;
    }
    
    public function delete(ExchangeRate $exchangeRate): bool
    {
        return $exchangeRate->delete();
    }
    
    public function findById(string $id): ?ExchangeRate
    {
        return ExchangeRate::with(['sourceCurrency', 'targetCurrency'])->find($id);
    }
    
    public function findExactRate(string $businessId, string $sourceCurrencyId, string $targetCurrencyId, string $effectiveDate): ?ExchangeRate
    {
        return ExchangeRate::where('business_id', $businessId)
            ->where('source_currency_id', $sourceCurrencyId)
            ->where('target_currency_id', $targetCurrencyId)
            ->where('effective_date', $effectiveDate)
            ->first();
    }
    
    public function paginate(ExchangeRateListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return ExchangeRate::with(['sourceCurrency', 'targetCurrency'])
            ->where('business_id', $criteria->businessId)
            ->orderBy('effective_date', 'desc')
            ->paginate($criteria->perPage);
    }
    
    public function search(ExchangeRateSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = ExchangeRate::with(['sourceCurrency', 'targetCurrency'])
            ->where('business_id', $criteria->businessId);
            
        if ($criteria->sourceCurrencyId) {
            $query->where('source_currency_id', $criteria->sourceCurrencyId);
        }

        if ($criteria->targetCurrencyId) {
            $query->where('target_currency_id', $criteria->targetCurrencyId);
        }
        
        if ($criteria->effectiveDate) {
            $query->where('effective_date', $criteria->effectiveDate);
        }
        
        return $query->orderBy('effective_date', 'desc')->paginate($criteria->perPage);
    }
    
    public function isUsedInJournalEntries(string $id): bool
    {
        $rate = ExchangeRate::find($id);
        if (!$rate) return false;

        // ExchangeRate is snapshot inside journal_entries, but we need to track if it's used.
        // Wait, the document says: "تعديل أو حذف ExchangeRate مستقبلاً لا يؤثر إطلاقاً على القيود السابقة؛ السعر المُستخدم في القيد يصبح Immutable."
        // And "يمنع حذف ExchangeRate إذا كان مستخدماً في أي عملية تشغيلية أو تم أخذ Snapshot منه داخل أي JournalEntry"
        // But JournalEntry doesn't have exchange_rate_id, it only has exchange_rate.
        // To enforce this strictly, we would have to either check if a JournalEntry exists with the same date/currency/rate or add an exchange_rate_id column.
        // Since V1 design doesn't have exchange_rate_id in JournalEntry, we will verify by looking at journal_entries on the same date/currency/rate.
        // Or if there's any journal entry on that date for that currency.
        // Let's assume if there's any journal entry on that date with that currency.
        $usedInHeader = \App\Domains\Finance\Models\JournalEntry::where('business_id', $rate->business_id)
            ->whereDate('journal_date', $rate->effective_date)
            ->where('currency_id', $rate->source_currency_id) // assuming source is the entry currency
            ->exists();

        $usedInLines = \App\Domains\Finance\Models\JournalEntryLine::where('business_id', $rate->business_id)
            ->whereHas('journalEntry', function($q) use ($rate) {
                $q->whereDate('journal_date', $rate->effective_date);
            })
            ->where('line_currency_id', $rate->source_currency_id)
            ->exists();

        return $usedInHeader || $usedInLines;
    }
}
