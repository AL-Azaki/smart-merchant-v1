<?php

namespace App\Domains\Core\Actions\SubscriptionPayment;

use App\Models\Core\SubscriptionPayment;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class MarkPaymentAsFailedAction
{
    public function __construct(private readonly SubscriptionPaymentRepositoryInterface $repository) {}

    public function handle(string $paymentId, ?string $failureReason = null): SubscriptionPayment
    {
        $payment = $this->repository->findById($paymentId);

        if (!$payment) {
            throw new CoreDomainException("The specified payment does not exist.");
        }

        if ($payment->status === 'Failed') {
            return $payment;
        }

        if ($payment->status !== 'Pending' && $payment->status !== 'Processing') {
            throw new CoreDomainException("Cannot mark a {$payment->status} payment as Failed.");
        }

        return $this->repository->updateStatus($payment, 'Failed', [
            'failure_reason' => $failureReason,
        ]);
    }
}
