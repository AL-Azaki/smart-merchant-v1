<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Models\Core\Subscription;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CloseSubscriptionAction
{
    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(string $subscriptionId, string $closeReason): Subscription
    {
        $subscription = $this->repository->findById($subscriptionId);

        if (!$subscription) {
            throw new CoreDomainException("The specified subscription does not exist.");
        }

        if ($subscription->status === 'Closed') {
            return $subscription;
        }

        $validReasons = ['upgraded', 'downgraded', 'renewed'];
        if (!in_array($closeReason, $validReasons)) {
            throw new CoreDomainException("Invalid close reason. Must be one of: " . implode(', ', $validReasons));
        }

        return $this->repository->updateStatus($subscription, 'Closed', $closeReason);
    }
}
