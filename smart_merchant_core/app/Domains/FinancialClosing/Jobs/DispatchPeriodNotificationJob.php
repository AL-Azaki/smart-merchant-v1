<?php

namespace App\Domains\FinancialClosing\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Services\Integration\Notification\PeriodNotificationBuilder;

class DispatchPeriodNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $periodId;
    public string $eventName;
    public ?string $reason;

    public function __construct(string $periodId, string $eventName, ?string $reason = null)
    {
        $this->periodId = $periodId;
        $this->eventName = $eventName;
        $this->reason = $reason;
    }

    public function handle(PeriodNotificationBuilder $builder): void
    {
        $period = AccountingPeriod::find($this->periodId);
        if (!$period) {
            return;
        }

        if ($this->eventName === 'AccountingPeriodClosed') {
            $builder->buildClosedNotification($period);
        } elseif ($this->eventName === 'AccountingPeriodReopened') {
            $builder->buildReopenedNotification($period, $this->reason ?? '');
        }
    }
}
