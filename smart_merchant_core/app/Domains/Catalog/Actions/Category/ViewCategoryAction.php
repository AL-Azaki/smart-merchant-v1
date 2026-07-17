<?php

namespace App\Domains\Catalog\Actions\Category;

use App\Domains\Catalog\Models\Category;
use App\Domains\Catalog\DTOs\ViewCategoryDTO;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\Exceptions\CatalogDomainException;

class ViewCategoryAction
{
    public function __construct(private readonly CategoryRepositoryInterface $repository) {}

    public function handle(ViewCategoryDTO $dto): Category
    {
        $category = $this->repository->findById($dto->CategoryId);

        if (!$category) {
            throw new CatalogDomainException("The specified Category does not exist.");
        }

        return $category;
    }
}




