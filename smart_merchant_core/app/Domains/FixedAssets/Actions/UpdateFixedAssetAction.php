<?php

namespace App\Domains\FixedAssets\Actions;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class UpdateFixedAssetAction
{
    private FixedAssetRepositoryInterface $repository;

    public function __construct(FixedAssetRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): FixedAsset
    {
        return DB::transaction(function () use ($id, $data) {
            $asset = $this->repository->findByIdOrFail($id);

            if ($asset->status === 'Disposed') {
                throw new RuntimeException("Cannot update a disposed asset.");
            }

            // Acquisition cost is immutable after activation
            if ($asset->status !== 'Draft' && isset($data['acquisition_cost'])) {
                throw new RuntimeException("Acquisition cost cannot be modified after activation.");
            }

            return $this->repository->update($asset, $data);
        });
    }
}
