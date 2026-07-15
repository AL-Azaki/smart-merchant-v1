<?php

namespace App\Domains\Core\Actions\SubscriptionPayment;

use App\Models\Core\SubscriptionPayment;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\Actions\Subscription\ActivateSubscriptionAction;
use App\Domains\Core\Exceptions\CoreDomainException;

class MarkPaymentAsSucceededAction
{
    public function __construct(
        private readonly SubscriptionPaymentRepositoryInterface $repository,
        private readonly ActivateSubscriptionAction $activateSubscriptionAction
    ) {}

    public function handle(string $paymentId, ?string $transactionId = null, ?string $receiptUrl = null): SubscriptionPayment
    {
        $payment = $this->repository->findById($paymentId);

        if (!$payment) {
            throw new CoreDomainException("The specified payment does not exist.");
        }

        if ($payment->status === 'Succeeded') {
            return $payment;
        }

        if ($payment->status !== 'Pending' && $payment->status !== 'Processing') {
            throw new CoreDomainException("Cannot mark a {$payment->status} payment as Succeeded.");
        }

        $payment = $this->repository->updateStatus($payment, 'Succeeded', [
            'transaction_id' => $transactionId,
            'receipt_url'    => $receiptUrl,
        ]);

        // @todo: Replace this direct call with a "PaymentSucceeded" Event in the future
        // so that the activation is decoupled entirely via event listeners.
        $this->activateSubscriptionAction->handle($payment->subscription_id, null);

        return $payment;
    }
}
