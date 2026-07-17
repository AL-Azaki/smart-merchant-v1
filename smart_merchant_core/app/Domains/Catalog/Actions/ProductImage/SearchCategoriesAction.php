<?php

namespace App\Domains\Catalog\Actions\productImageImage;

use App\Domains\Catalog\DTOs\productImageImagesearchCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\productImageImageRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchproductImageImagesAction
{
    public function __construct(private readonly productImageImageRepositoryInterface $repository) {}

    public function handle(productImageImagesearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}




