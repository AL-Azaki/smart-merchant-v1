<?php

namespace App\Domains\FixedAssets\Actions;

use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Collection;

class ListFixedAssetsAction
{
    private FixedAssetRepositoryInterface $repository;

    public function __construct(FixedAssetRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $businessId): Collection
    {
        return $this->repository->findByBusinessId($businessId);
    }
}
