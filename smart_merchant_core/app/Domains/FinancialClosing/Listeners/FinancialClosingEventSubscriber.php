<?php

namespace App\Domains\FinancialClosing\Listeners;

use App\Domains\FinancialClosing\Events\AccountingPeriodClosed;
use App\Domains\FinancialClosing\Events\AccountingPeriodReopened;
use App\Domains\FinancialClosing\Jobs\DispatchPeriodNotificationJob;
use Illuminate\Events\Dispatcher;

class FinancialClosingEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(AccountingPeriodClosed::class, [self::class, 'onPeriodClosed']);
        $events->listen(AccountingPeriodReopened::class, [self::class, 'onPeriodReopened']);
    }

    public function onPeriodClosed(AccountingPeriodClosed $event): void
    {
        DispatchPeriodNotificationJob::dispatch(
            $event->period->id,
            'AccountingPeriodClosed'
        );
    }

    public function onPeriodReopened(AccountingPeriodReopened $event): void
    {
        DispatchPeriodNotificationJob::dispatch(
            $event->period->id,
            'AccountingPeriodReopened',
            $event->reason
        );
    }
}
