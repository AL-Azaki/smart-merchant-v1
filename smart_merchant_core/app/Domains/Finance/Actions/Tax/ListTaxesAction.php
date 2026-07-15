<?php

namespace App\Domains\Finance\Actions\Tax;

use App\Domains\Finance\DTOs\TaxListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListTaxesAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(TaxListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
