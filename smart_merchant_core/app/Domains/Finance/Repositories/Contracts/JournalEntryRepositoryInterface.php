<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\JournalEntry;

interface JournalEntryRepositoryInterface
{
    public function create(array $data): JournalEntry;
    
    public function update(JournalEntry $journalEntry, array $data): JournalEntry;
    
    public function findById(string $id): ?JournalEntry;
    
    public function findByDocument(string $businessId, string $documentType, string $documentId): ?JournalEntry;
    
    public function getNextJournalNumber(string $businessId): string;
}
