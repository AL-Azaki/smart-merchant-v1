<?php

namespace App\Domains\AccountsPayable\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\Integration\NotificationPlatformInterface;
use App\Domains\AccountsPayable\Services\Integration\Notification\PayableNotificationBuilder;
use App\Domains\AccountsPayable\Models\PayableEntry;

class DispatchPayableNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $entryId;

    public function __construct(string $entryId)
    {
        $this->entryId = $entryId;
    }

    public function handle(
        NotificationPlatformInterface $notificationPlatform,
        PayableNotificationBuilder $builder
    ): void {
        $entry = PayableEntry::find($this->entryId);
        if (! $entry) return;

        $request = $builder->build($entry, 'PayableEntryRecorded');
        $notificationPlatform->dispatch($request);
    }
}
