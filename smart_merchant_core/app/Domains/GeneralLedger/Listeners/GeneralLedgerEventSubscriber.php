<?php

namespace App\Domains\GeneralLedger\Listeners;

use App\Domains\GeneralLedger\Events\JournalEntryPosted;
use App\Domains\GeneralLedger\Jobs\DispatchJournalNotificationJob;
use Illuminate\Events\Dispatcher;

class GeneralLedgerEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(JournalEntryPosted::class, [self::class, 'onJournalEntryPosted']);
    }

    public function onJournalEntryPosted(JournalEntryPosted $event): void
    {
        // Dispatch Notification Job after successful post
        DispatchJournalNotificationJob::dispatch($event->entry->id, 'JournalEntryPosted');
    }
}
