<?php

namespace App\Domains\FixedAssets\Actions;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class ActivateFixedAssetAction
{
    private FixedAssetRepositoryInterface $repository;

    public function __construct(FixedAssetRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, string $activatedBy): FixedAsset
    {
        return DB::transaction(function () use ($id, $activatedBy) {
            $asset = $this->repository->findByIdOrFail($id);

            if ($asset->status !== 'Draft') {
                throw new RuntimeException("Only Draft assets can be activated.");
            }

            return $this->repository->update($asset, [
                'status' => 'Active',
                'updated_by' => $activatedBy,
            ]);
        });
    }
}
