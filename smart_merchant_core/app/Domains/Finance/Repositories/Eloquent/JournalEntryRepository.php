<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Facades\DB;

class JournalEntryRepository implements JournalEntryRepositoryInterface
{
    public function create(array $data): JournalEntry
    {
        return JournalEntry::create($data);
    }
    
    public function update(JournalEntry $journalEntry, array $data): JournalEntry
    {
        $journalEntry->update($data);
        return $journalEntry;
    }
    
    public function findById(string $id): ?JournalEntry
    {
        return JournalEntry::find($id);
    }
    
    public function findByDocument(string $businessId, string $documentType, string $documentId): ?JournalEntry
    {
        return JournalEntry::where('business_id', $businessId)
            ->where('document_type', $documentType)
            ->where('document_id', $documentId)
            ->first();
    }
    
    public function getNextJournalNumber(string $businessId): string
    {
        // Simple implementation, in real world might need sequence or locking
        $lastJournal = JournalEntry::where('business_id', $businessId)
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->first();
            
        if (!$lastJournal || !preg_match('/^JE-(\d+)$/', $lastJournal->journal_number, $matches)) {
            return 'JE-1000';
        }
        
        $nextNumber = (int)$matches[1] + 1;
        return 'JE-' . $nextNumber;
    }
}
