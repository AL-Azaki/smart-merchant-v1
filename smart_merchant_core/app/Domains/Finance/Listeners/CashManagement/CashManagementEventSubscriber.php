<?php

namespace App\Domains\Finance\Listeners\CashManagement;

use App\Domains\Finance\Events\CashManagement\CashRegisterOpened;
use App\Domains\Finance\Events\CashManagement\CashRegisterClosed;
use App\Domains\Finance\Events\CashManagement\CashTransactionCreated;
use App\Domains\Finance\Events\CashManagement\CashTransactionReversed;
use App\Domains\Finance\Jobs\CashManagement\DispatchCashNotificationJob;
use App\Domains\Finance\Jobs\CashManagement\RefreshCashDashboardJob;
use Illuminate\Events\Dispatcher;

class CashManagementEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(CashRegisterOpened::class, [self::class, 'onRegisterOpened']);
        $events->listen(CashRegisterClosed::class, [self::class, 'onRegisterClosed']);
        $events->listen(CashTransactionCreated::class, [self::class, 'onTransactionCreated']);
        $events->listen(CashTransactionReversed::class, [self::class, 'onTransactionReversed']);
    }

    public function onRegisterOpened(CashRegisterOpened $event): void
    {
        $register = $event->cashRegister;
        DispatchCashNotificationJob::dispatch('CashRegisterOpened', $register->id, $register->business_id);
        RefreshCashDashboardJob::dispatch($register->business_id, $register->id);
    }

    public function onRegisterClosed(CashRegisterClosed $event): void
    {
        $register = $event->cashRegister;
        DispatchCashNotificationJob::dispatch('CashRegisterClosed', $register->id, $register->business_id);
        RefreshCashDashboardJob::dispatch($register->business_id, $register->id);
    }

    public function onTransactionCreated(CashTransactionCreated $event): void
    {
        $transaction = $event->transaction;
        DispatchCashNotificationJob::dispatch('CashTransactionCreated', $transaction->id, $transaction->business_id);
        RefreshCashDashboardJob::dispatch($transaction->business_id, $transaction->cash_register_id);
    }

    public function onTransactionReversed(CashTransactionReversed $event): void
    {
        $transaction = $event->transaction;
        DispatchCashNotificationJob::dispatch('CashTransactionReversed', $transaction->id, $transaction->business_id);
        RefreshCashDashboardJob::dispatch($transaction->business_id, $transaction->cash_register_id);
    }
}
