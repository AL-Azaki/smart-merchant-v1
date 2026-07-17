<?php

namespace App\Domains\AccountsReceivable\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\Integration\NotificationPlatformInterface;
use App\Domains\AccountsReceivable\Services\Integration\Notification\ReceivableNotificationBuilder;
use App\Domains\AccountsReceivable\Models\ReceivableEntry;

class DispatchReceivableNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $entryId;

    public function __construct(string $entryId)
    {
        $this->entryId = $entryId;
    }

    public function handle(
        NotificationPlatformInterface $notificationPlatform,
        ReceivableNotificationBuilder $builder
    ): void {
        $entry = ReceivableEntry::find($this->entryId);
        if (! $entry) return;

        $request = $builder->build($entry, 'ReceivableEntryRecorded');
        $notificationPlatform->dispatch($request);
    }
}
