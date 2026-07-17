<?php

namespace App\Domains\Catalog\Actions\Unit;

use App\Domains\Catalog\DTOs\UnitListCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListUnitsAction
{
    public function __construct(private readonly UnitRepositoryInterface $repository) {}

    public function handle(UnitListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
