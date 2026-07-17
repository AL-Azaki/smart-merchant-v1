<?php

namespace App\Domains\Catalog\Actions\productImageImage;

use App\Domains\Catalog\DTOs\productImageImageListCriteriaDTO;
use App\Domains\Catalog\Repositories\Contracts\productImageImageRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListproductImageImagesAction
{
    public function __construct(private readonly productImageImageRepositoryInterface $repository) {}

    public function handle(productImageImageListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}




