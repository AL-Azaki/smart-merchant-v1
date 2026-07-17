<?php

namespace App\Domains\FixedAssets\Repositories\Contracts;

use App\Domains\FixedAssets\Models\FixedAsset;
use Illuminate\Support\Collection;

interface FixedAssetRepositoryInterface
{
    public function findById(string $id): ?FixedAsset;

    public function findByIdOrFail(string $id): FixedAsset;

    public function findByBusinessId(string $businessId): Collection;

    public function create(array $data): FixedAsset;

    public function update(FixedAsset $asset, array $data): FixedAsset;

    /**
     * Load the full aggregate: FixedAsset with its DepreciationSchedules.
     */
    public function loadAggregate(string $id): FixedAsset;
}
