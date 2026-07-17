<?php

namespace App\Domains\GeneralLedger\Events;

use App\Domains\Finance\Models\JournalEntry;

class JournalEntryPosted
{
    public JournalEntry $entry;
    public string $userId;

    public function __construct(JournalEntry $entry, string $userId)
    {
        $this->entry = $entry;
        $this->userId = $userId;
    }
}
