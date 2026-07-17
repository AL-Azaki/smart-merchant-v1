<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Domains\Core\Models\Subscription;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CancelSubscriptionAction
{
    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(string $subscriptionId): Subscription
    {
        $subscription = $this->repository->findById($subscriptionId);

        if (!$subscription) {
            throw new CoreDomainException("The specified subscription does not exist.");
        }

        if ($subscription->status === 'Cancelled') {
            return $subscription;
        }

        return $this->repository->updateStatus($subscription, 'Cancelled', 'cancelled');
    }
}
