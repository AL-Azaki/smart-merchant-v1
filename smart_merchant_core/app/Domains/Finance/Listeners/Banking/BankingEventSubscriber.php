<?php

namespace App\Domains\Finance\Listeners\Banking;

use App\Domains\Finance\Events\Banking\BankAccountFrozen;
use App\Domains\Finance\Events\Banking\BankAccountClosed;
use App\Domains\Finance\Events\Banking\BankTransactionCreated;
use App\Domains\Finance\Jobs\Banking\DispatchBankNotificationJob;
use App\Domains\Finance\Jobs\Banking\RefreshBankDashboardJob;
use Illuminate\Events\Dispatcher;

class BankingEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(BankAccountFrozen::class, [self::class, 'onAccountFrozen']);
        $events->listen(BankAccountClosed::class, [self::class, 'onAccountClosed']);
        $events->listen(BankTransactionCreated::class, [self::class, 'onTransactionCreated']);
    }

    public function onAccountFrozen(BankAccountFrozen $event): void
    {
        $account = $event->bankAccount;
        DispatchBankNotificationJob::dispatch('BankAccountFrozen', $account->id, $account->business_id);
        RefreshBankDashboardJob::dispatch($account->business_id, $account->id);
    }

    public function onAccountClosed(BankAccountClosed $event): void
    {
        $account = $event->bankAccount;
        DispatchBankNotificationJob::dispatch('BankAccountClosed', $account->id, $account->business_id);
        RefreshBankDashboardJob::dispatch($account->business_id, $account->id);
    }

    public function onTransactionCreated(BankTransactionCreated $event): void
    {
        $transaction = $event->transaction;
        DispatchBankNotificationJob::dispatch('BankTransactionCreated', $transaction->id, $transaction->business_id);
        RefreshBankDashboardJob::dispatch($transaction->business_id, $transaction->bank_account_id);
    }
}
