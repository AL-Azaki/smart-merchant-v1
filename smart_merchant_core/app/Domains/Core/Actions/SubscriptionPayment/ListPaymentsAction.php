<?php

namespace App\Domains\Core\Actions\SubscriptionPayment;

use App\Domains\Core\DTOs\PaymentListCriteriaDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListPaymentsAction
{
    public function __construct(private readonly SubscriptionPaymentRepositoryInterface $repository) {}

    public function handle(PaymentListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
