<?php

namespace App\Domains\GeneralLedger\Repositories\Eloquent;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Collection;

class JournalEntryEloquentRepository implements JournalEntryRepositoryInterface
{
    public function create(array $data): JournalEntry
    {
        return JournalEntry::create($data);
    }

    public function update(string $id, array $data): JournalEntry
    {
        $entry = JournalEntry::findOrFail($id);
        $entry->update($data);
        return $entry;
    }

    public function findById(string $id): ?JournalEntry
    {
        return JournalEntry::find($id);
    }

    public function list(array $filters = []): Collection
    {
        $query = JournalEntry::query();

        if (isset($filters['business_id'])) {
            $query->where('business_id', $filters['business_id']);
        }
        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        if (isset($filters['fiscal_year_id'])) {
            $query->where('fiscal_year_id', $filters['fiscal_year_id']);
        }

        return $query->get();
    }

    public function loadAggregate(string $id): ?JournalEntry
    {
        return JournalEntry::with(['lines', 'business', 'branch', 'fiscalPeriod', 'currency', 'creator', 'poster', 'reverser'])->find($id);
    }

    public function syncLines(string $journalEntryId, array $linesData): void
    {
        $entry = JournalEntry::findOrFail($journalEntryId);
        $entry->lines()->delete();
        $entry->lines()->createMany($linesData);
    }
}
