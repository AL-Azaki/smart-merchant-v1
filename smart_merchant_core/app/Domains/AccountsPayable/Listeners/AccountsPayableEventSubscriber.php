<?php

namespace App\Domains\AccountsPayable\Listeners;

use App\Domains\AccountsPayable\Events\PayableEntryRecorded;
use App\Domains\AccountsPayable\Jobs\ProcessPayablePostingJob;
use App\Domains\AccountsPayable\Jobs\DispatchPayableNotificationJob;
use Illuminate\Events\Dispatcher;

class AccountsPayableEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(PayableEntryRecorded::class, [self::class, 'onEntryRecorded']);
    }

    public function onEntryRecorded(PayableEntryRecorded $event): void
    {
        $entry = $event->entry;

        // Dispatch GL Posting Job
        ProcessPayablePostingJob::dispatch($entry->id);

        // Dispatch Notification Job
        DispatchPayableNotificationJob::dispatch($entry->id);
    }
}
