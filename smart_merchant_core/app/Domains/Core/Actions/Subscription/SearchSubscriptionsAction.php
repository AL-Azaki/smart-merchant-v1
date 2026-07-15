<?php

namespace App\Domains\Core\Actions\Subscription;

use App\Domains\Core\DTOs\SubscriptionSearchCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchSubscriptionsAction
{
    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(SubscriptionSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
