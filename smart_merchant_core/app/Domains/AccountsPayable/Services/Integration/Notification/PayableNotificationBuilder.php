<?php

namespace App\Domains\AccountsPayable\Services\Integration\Notification;

use App\Domains\AccountsPayable\Models\PayableEntry;
use App\Domains\Finance\DTOs\NotificationRequestDTO;

class PayableNotificationBuilder
{
    public function build(PayableEntry $entry, string $eventName): NotificationRequestDTO
    {
        return new NotificationRequestDTO(
            businessId: $entry->business_id,
            module: 'AccountsPayable',
            entityType: 'PayableEntry',
            entityId: $entry->id,
            title: "New AP Entry: {$entry->entry_type}",
            message: "A {$entry->direction} of {$entry->amount} was recorded.",
            level: 'info',
            metadata: [
                'entry_type' => $entry->entry_type,
                'direction' => $entry->direction,
            ]
        );
    }
}
