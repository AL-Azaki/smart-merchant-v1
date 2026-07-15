<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\DTOs\PaymentTermListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListPaymentTermsAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(PaymentTermListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
