<?php

namespace App\Domains\Finance\Jobs\Banking;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\Integration\NotificationPlatformInterface;
use App\Domains\Finance\Services\Banking\Notification\BankNotificationBuilder;
use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Models\BankTransaction;

class DispatchBankNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public string $eventName;
    public string $entityId;
    public string $businessId;

    public function __construct(string $eventName, string $entityId, string $businessId)
    {
        $this->eventName = $eventName;
        $this->entityId = $entityId;
        $this->businessId = $businessId;
    }

    public function handle(
        NotificationPlatformInterface $notificationPlatform,
        BankNotificationBuilder $builder
    ): void {
        if (str_contains($this->eventName, 'Account')) {
            $entity = BankAccount::find($this->entityId);
            if (! $entity) return;
            $request = $builder->buildFromAccount($entity, $this->eventName);
        } else {
            $entity = BankTransaction::find($this->entityId);
            if (! $entity) return;
            $request = $builder->buildFromTransaction($entity, $this->eventName);
        }

        $notificationPlatform->dispatch($request);
    }
}
