<?php

namespace App\Domains\Finance\Listeners\Payment;

use App\Domains\Finance\Events\Payment\PaymentCreated;
use App\Domains\Finance\Events\Payment\PaymentPosted;
use App\Domains\Finance\Events\Payment\PaymentReversed;
use App\Domains\Finance\Jobs\Payment\DispatchPaymentNotificationJob;
use App\Domains\Finance\Jobs\Payment\RefreshPaymentReportsJob;
use Illuminate\Events\Dispatcher;

class PaymentEventSubscriber
{
    public function handlePaymentCreated(PaymentCreated $event)
    {
        DispatchPaymentNotificationJob::dispatch($event->payment, 'PaymentCreated');
    }

    public function handlePaymentPosted(PaymentPosted $event)
    {
        DispatchPaymentNotificationJob::dispatch($event->payment, 'PaymentPosted');
        RefreshPaymentReportsJob::dispatch($event->payment);
    }

    public function handlePaymentReversed(PaymentReversed $event)
    {
        DispatchPaymentNotificationJob::dispatch($event->payment, 'PaymentReversed');
        RefreshPaymentReportsJob::dispatch($event->payment);
    }

    public function subscribe(Dispatcher $events)
    {
        $events->listen(
            PaymentCreated::class,
            [PaymentEventSubscriber::class, 'handlePaymentCreated']
        );

        $events->listen(
            PaymentPosted::class,
            [PaymentEventSubscriber::class, 'handlePaymentPosted']
        );

        $events->listen(
            PaymentReversed::class,
            [PaymentEventSubscriber::class, 'handlePaymentReversed']
        );
    }
}
