<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use App\Domains\Finance\Models\Payment;

class LoadPaymentAggregateAction
{
    private PaymentRepositoryInterface $repository;

    public function __construct(PaymentRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): ?Payment
    {
        return $this->repository->loadAggregate($id);
    }
}
