<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Domains\Core\DTOs\SubscriptionListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListSubscriptionsAction
{
    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(SubscriptionListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
