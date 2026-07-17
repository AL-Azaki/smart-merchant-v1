<?php

namespace App\Domains\FixedAssets\Actions;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Facades\DB;

class CreateFixedAssetAction
{
    private FixedAssetRepositoryInterface $repository;

    public function __construct(FixedAssetRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): FixedAsset
    {
        return DB::transaction(function () use ($data) {
            $data['status'] = 'Draft';
            return $this->repository->create($data);
        });
    }
}
