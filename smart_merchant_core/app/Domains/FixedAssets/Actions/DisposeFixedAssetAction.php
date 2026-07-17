<?php

namespace App\Domains\FixedAssets\Actions;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class DisposeFixedAssetAction
{
    private FixedAssetRepositoryInterface $repository;

    public function __construct(FixedAssetRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, string $disposedBy): FixedAsset
    {
        return DB::transaction(function () use ($id, $disposedBy) {
            $asset = $this->repository->findByIdOrFail($id);

            if ($asset->status === 'Draft') {
                throw new RuntimeException("An asset cannot be disposed while in Draft status.");
            }

            if ($asset->status === 'Disposed') {
                throw new RuntimeException("Asset is already disposed.");
            }

            // Cancel any pending/ready depreciation schedules
            $asset->depreciationSchedules()
                ->whereIn('status', ['Pending', 'Ready'])
                ->update([
                    'status' => 'Cancelled',
                    'updated_by' => $disposedBy,
                ]);

            return $this->repository->update($asset, [
                'status' => 'Disposed',
                'updated_by' => $disposedBy,
            ]);
        });
    }
}
