<?php

namespace App\Domains\Finance\Jobs\CashManagement;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\Integration\NotificationPlatformInterface;
use App\Domains\Finance\Services\CashManagement\Notification\CashNotificationBuilder;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Models\CashTransaction;

class DispatchCashNotificationJob implements ShouldQueue
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
        CashNotificationBuilder $builder
    ): void {
        // Resolve the entity and build the notification request
        if (str_contains($this->eventName, 'Register')) {
            $entity = CashRegister::find($this->entityId);
            if (! $entity) return;
            $request = $builder->buildFromRegister($entity, $this->eventName);
        } else {
            $entity = CashTransaction::find($this->entityId);
            if (! $entity) return;
            $request = $builder->buildFromTransaction($entity, $this->eventName);
        }

        $notificationPlatform->dispatch($request);
    }
}
