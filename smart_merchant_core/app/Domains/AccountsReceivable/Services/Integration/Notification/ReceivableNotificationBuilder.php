<?php

namespace App\Domains\AccountsReceivable\Services\Integration\Notification;

use App\Domains\AccountsReceivable\Models\ReceivableEntry;
use App\Domains\Finance\DTOs\NotificationRequestDTO;

class ReceivableNotificationBuilder
{
    public function build(ReceivableEntry $entry, string $eventName): NotificationRequestDTO
    {
        return new NotificationRequestDTO(
            businessId: $entry->business_id,
            module: 'AccountsReceivable',
            entityType: 'ReceivableEntry',
            entityId: $entry->id,
            title: "New AR Entry: {$entry->entry_type}",
            message: "A {$entry->direction} of {$entry->amount} was recorded.",
            level: 'info',
            metadata: [
                'entry_type' => $entry->entry_type,
                'direction' => $entry->direction,
            ]
        );
    }
}
