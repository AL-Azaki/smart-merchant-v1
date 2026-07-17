<?php

namespace App\Domains\GeneralLedger\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\Integration\NotificationPlatformInterface;
use App\Domains\GeneralLedger\Services\Integration\Notification\JournalNotificationBuilder;
use App\Domains\Finance\Models\JournalEntry;

class DispatchJournalNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $journalEntryId;
    public string $eventName;

    public function __construct(string $journalEntryId, string $eventName)
    {
        $this->journalEntryId = $journalEntryId;
        $this->eventName = $eventName;
    }

    public function handle(
        NotificationPlatformInterface $notificationPlatform,
        JournalNotificationBuilder $builder
    ): void {
        $entry = JournalEntry::find($this->journalEntryId);
        if (!$entry) return;

        $request = $builder->build($entry, $this->eventName);
        $notificationPlatform->dispatch($request);
    }
}
