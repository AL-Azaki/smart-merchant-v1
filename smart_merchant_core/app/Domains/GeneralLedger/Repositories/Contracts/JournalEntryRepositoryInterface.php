<?php

namespace App\Domains\GeneralLedger\Repositories\Contracts;

use App\Domains\Finance\Models\JournalEntry;
use Illuminate\Support\Collection;

interface JournalEntryRepositoryInterface
{
    public function create(array $data): JournalEntry;
    
    public function update(string $id, array $data): JournalEntry;
    
    public function findById(string $id): ?JournalEntry;
    
    public function list(array $filters = []): Collection;
    
    public function loadAggregate(string $id): ?JournalEntry;
    
    public function syncLines(string $journalEntryId, array $linesData): void;
}
