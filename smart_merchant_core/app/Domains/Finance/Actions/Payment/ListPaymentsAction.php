<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use Illuminate\Support\Collection;

class ListPaymentsAction
{
    private PaymentRepositoryInterface $repository;

    public function __construct(PaymentRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId, array $filters = []): Collection
    {
        return $this->repository->list($businessId, $filters);
    }
}
