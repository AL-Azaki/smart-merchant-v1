<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Models\Core\Subscription;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class SuspendSubscriptionAction
{
    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(string $subscriptionId): Subscription
    {
        $subscription = $this->repository->findById($subscriptionId);

        if (!$subscription) {
            throw new CoreDomainException("The specified subscription does not exist.");
        }

        if ($subscription->status === 'Suspended') {
            return $subscription;
        }

        if ($subscription->status !== 'Active') {
            throw new CoreDomainException("Only Active subscriptions can be suspended.");
        }

        return $this->repository->updateStatus($subscription, 'Suspended');
    }
}
