<?php

namespace App\Domains\Finance\Actions\PaymentTerm;

use App\Domains\Finance\DTOs\PaymentTermSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchPaymentTermsAction
{
    public function __construct(private readonly PaymentTermRepositoryInterface $repository) {}

    public function handle(PaymentTermSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
