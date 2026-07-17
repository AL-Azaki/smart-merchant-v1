<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Domains\Core\Models\Subscription;
use App\Domains\Core\DTOs\ViewSubscriptionDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewSubscriptionAction
{
    private const ALLOWED_INCLUDES = ['plan', 'currency', 'account'];

    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(ViewSubscriptionDTO $dto, string $accountId): Subscription
    {
        $validIncludes = array_intersect($dto->includes, self::ALLOWED_INCLUDES);
        $subscription = $this->repository->findByIdWithRelations($dto->subscriptionId, $validIncludes);

        if (!$subscription) {
            throw new CoreDomainException("The specified subscription does not exist.");
        }

        if ($subscription->account_id !== $accountId) {
            throw new CoreDomainException("Unauthorized access to the specified subscription.");
        }

        return $subscription;
    }
}
