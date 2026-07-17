<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\Subscription;

interface SubscriptionRepositoryInterface
{
    public function create(array $data): Subscription;

    public function findById(string $id): ?Subscription;

    public function findByIdWithRelations(string $id, array $relations = []): ?Subscription;

    public function paginate(\App\Domains\Core\DTOs\SubscriptionListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\SubscriptionSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function updateStatus(Subscription $subscription, string $status, ?string $closeReason = null): Subscription;
    
    public function updateDates(Subscription $subscription, array $dates): Subscription;

    public function hasActiveSubscription(string $accountId): bool;
}
