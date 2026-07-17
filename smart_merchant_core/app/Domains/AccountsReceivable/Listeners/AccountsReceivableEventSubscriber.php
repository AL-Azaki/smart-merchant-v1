<?php

namespace App\Domains\AccountsReceivable\Listeners;

use App\Domains\AccountsReceivable\Events\ReceivableEntryRecorded;
use App\Domains\AccountsReceivable\Jobs\ProcessReceivablePostingJob;
use App\Domains\AccountsReceivable\Jobs\DispatchReceivableNotificationJob;
use Illuminate\Events\Dispatcher;

class AccountsReceivableEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(ReceivableEntryRecorded::class, [self::class, 'onEntryRecorded']);
    }

    public function onEntryRecorded(ReceivableEntryRecorded $event): void
    {
        $entry = $event->entry;
        
        // Dispatch GL Posting Job
        ProcessReceivablePostingJob::dispatch($entry->id);
        
        // Dispatch Notification Job
        DispatchReceivableNotificationJob::dispatch($entry->id);
    }
}
