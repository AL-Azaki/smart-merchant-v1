<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Models\Core\SubscriptionPayment;

interface SubscriptionPaymentRepositoryInterface
{
    public function create(array $data): SubscriptionPayment;

    public function findById(string $id): ?SubscriptionPayment;

    public function paginate(\App\Domains\Core\DTOs\PaymentListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function updateStatus(SubscriptionPayment $payment, string $status, array $data = []): SubscriptionPayment;

    public function hasSuccessfulPayment(string $subscriptionId): bool;
}
