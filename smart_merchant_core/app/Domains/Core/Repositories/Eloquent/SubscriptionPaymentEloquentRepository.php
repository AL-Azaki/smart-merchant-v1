<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Models\Core\SubscriptionPayment;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\DTOs\PaymentListCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SubscriptionPaymentEloquentRepository implements SubscriptionPaymentRepositoryInterface
{
    public function create(array $data): SubscriptionPayment
    {
        return SubscriptionPayment::create($data);
    }

    public function findById(string $id): ?SubscriptionPayment
    {
        return SubscriptionPayment::find($id);
    }

    public function paginate(PaymentListCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = SubscriptionPayment::where('subscription_id', $criteria->subscriptionId);

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function updateStatus(SubscriptionPayment $payment, string $status, array $data = []): SubscriptionPayment
    {
        $payload = array_merge(['status' => $status], $data);
        $payment->update($payload);
        return $payment;
    }

    public function hasSuccessfulPayment(string $subscriptionId): bool
    {
        return SubscriptionPayment::where('subscription_id', $subscriptionId)
                                  ->where('status', 'Succeeded')
                                  ->exists();
    }
}
