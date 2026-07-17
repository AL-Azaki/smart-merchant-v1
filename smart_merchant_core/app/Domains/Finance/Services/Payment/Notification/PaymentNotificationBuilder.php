<?php

namespace App\Domains\Finance\Services\Payment\Notification;

use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\DTOs\Integration\NotificationRequestDTO;

class PaymentNotificationBuilder
{
    public function build(Payment $payment, string $eventName): NotificationRequestDTO
    {
        $recipients = $this->resolveRecipients($payment);
        $channels = $this->resolveChannels($payment, $eventName);
        
        $title = $this->resolveTitle($payment, $eventName);
        $body = $this->resolveBody($payment, $eventName);
        
        return new NotificationRequestDTO(
            recipientIds: $recipients,
            channels: $channels,
            title: $title,
            body: $body,
            metadata: [
                'payment_id' => $payment->id,
                'business_id' => $payment->business_id,
                'event' => $eventName
            ]
        );
    }

    private function resolveRecipients(Payment $payment): array
    {
        $recipients = [];
        if ($payment->created_by) {
            $recipients[] = $payment->created_by;
        }
        if ($payment->posted_by && $payment->posted_by !== $payment->created_by) {
            $recipients[] = $payment->posted_by;
        }
        return array_unique($recipients);
    }

    private function resolveChannels(Payment $payment, string $eventName): array
    {
        if (in_array($eventName, ['PaymentPosted', 'PaymentReversed'])) {
            return ['In-App', 'Push'];
        }
        return ['In-App'];
    }
    
    private function resolveTitle(Payment $payment, string $eventName): string
    {
        return "Payment " . str_replace('Payment', '', $eventName);
    }

    private function resolveBody(Payment $payment, string $eventName): string
    {
        return "Payment #{$payment->payment_number} has been " . strtolower(str_replace('Payment', '', $eventName)) . ".";
    }
}
