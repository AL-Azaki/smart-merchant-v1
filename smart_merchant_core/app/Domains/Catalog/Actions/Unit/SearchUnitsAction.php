<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\DTOs\UnitSearchCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchUnitsAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(UnitSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
