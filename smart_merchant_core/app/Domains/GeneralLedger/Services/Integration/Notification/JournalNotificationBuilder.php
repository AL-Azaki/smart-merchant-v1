<?php

namespace App\Domains\GeneralLedger\Services\Integration\Notification;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\Finance\DTOs\NotificationRequestDTO;

class JournalNotificationBuilder
{
    public function build(JournalEntry $entry, string $eventName): NotificationRequestDTO
    {
        $action = $eventName === 'JournalEntryPosted' ? 'Posted' : 'Reversed';
        
        return new NotificationRequestDTO(
            businessId: $entry->business_id,
            module: 'GeneralLedger',
            entityType: 'JournalEntry',
            entityId: $entry->id,
            title: "Journal Entry {$action}",
            message: "Journal Entry {$entry->journal_number} has been {$action}.",
            level: 'info',
            metadata: [
                'journal_number' => $entry->journal_number,
                'status' => $entry->status,
                'document_type' => $entry->document_type,
            ]
        );
    }
}
