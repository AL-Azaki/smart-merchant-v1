<?php

namespace App\Domains\Core\Actions\SubscriptionPayment;

use App\Domains\Core\Models\SubscriptionPayment;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewPaymentAction
{
    public function __construct(private readonly SubscriptionPaymentRepositoryInterface $repository) {}

    public function handle(string $paymentId): SubscriptionPayment
    {
        $payment = $this->repository->findById($paymentId);

        if (!$payment) {
            throw new CoreDomainException("The specified payment does not exist.");
        }

        return $payment;
    }
}
