<?php

namespace App\Domains\Finance\Jobs\Payment;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\Contracts\Integration\NotificationPlatformInterface;
use App\Domains\Finance\Services\Payment\Notification\PaymentNotificationBuilder;

class DispatchPaymentNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;

    public Payment $payment;
    public string $eventName;

    public function __construct(Payment $payment, string $eventName)
    {
        $this->payment = $payment;
        $this->eventName = $eventName;
    }

    public function handle(
        NotificationPlatformInterface $notificationPlatform,
        PaymentNotificationBuilder $builder
    ) {
        $notificationRequest = $builder->build($this->payment, $this->eventName);
        $notificationPlatform->dispatch($notificationRequest);
    }
}
