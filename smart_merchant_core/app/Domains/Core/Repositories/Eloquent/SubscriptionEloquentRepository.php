<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\Subscription;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\DTOs\SubscriptionListCriteriaDTO;
use App\Domains\Core\DTOs\SubscriptionSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class SubscriptionEloquentRepository implements SubscriptionRepositoryInterface
{
    public function create(array $data): Subscription
    {
        return Subscription::create($data);
    }

    public function findById(string $id): ?Subscription
    {
        return Subscription::find($id);
    }

    public function findByIdWithRelations(string $id, array $relations = []): ?Subscription
    {
        return Subscription::with($relations)->find($id);
    }

    public function paginate(SubscriptionListCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Subscription::where('account_id', $criteria->accountId);

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function search(SubscriptionSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Subscription::where('account_id', $criteria->accountId);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('plan_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('close_reason', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->status !== null) {
            $query->where('status', $criteria->status);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function updateStatus(Subscription $subscription, string $status, ?string $closeReason = null): Subscription
    {
        $data = ['status' => $status];
        if ($closeReason !== null) {
            $data['close_reason'] = $closeReason;
        }
        $subscription->update($data);
        return $subscription;
    }

    public function updateDates(Subscription $subscription, array $dates): Subscription
    {
        $subscription->update($dates);
        return $subscription;
    }

    public function hasActiveSubscription(string $accountId): bool
    {
        return Subscription::where('account_id', $accountId)
                           ->where('status', 'Active')
                           ->exists();
    }

    public function findActiveByAccount(string $accountId): ?Subscription
    {
        return Subscription::where('account_id', $accountId)
                           ->where('status', 'Active')
                           ->first();
    }
}
