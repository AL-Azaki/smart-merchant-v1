<?php

namespace App\Domains\FixedAssets\Repositories\Eloquent;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Collection;

class FixedAssetEloquentRepository implements FixedAssetRepositoryInterface
{
    public function findById(string $id): ?FixedAsset
    {
        return FixedAsset::find($id);
    }

    public function findByIdOrFail(string $id): FixedAsset
    {
        return FixedAsset::findOrFail($id);
    }

    public function findByBusinessId(string $businessId): Collection
    {
        return FixedAsset::where('business_id', $businessId)
            ->orderBy('asset_code')
            ->get();
    }

    public function create(array $data): FixedAsset
    {
        return FixedAsset::create($data);
    }

    public function update(FixedAsset $asset, array $data): FixedAsset
    {
        $asset->update($data);
        return $asset->fresh();
    }

    public function loadAggregate(string $id): FixedAsset
    {
        return FixedAsset::with('depreciationSchedules')->findOrFail($id);
    }
}
