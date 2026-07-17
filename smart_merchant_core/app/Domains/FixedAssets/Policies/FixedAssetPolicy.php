<?php

namespace App\Domains\FixedAssets\Policies;

use App\Domains\Core\Models\User;
use App\Domains\FixedAssets\Models\FixedAsset;

class FixedAssetPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, FixedAsset $asset): bool
    {
        return $user->business_id === $asset->business_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, FixedAsset $asset): bool
    {
        return $user->business_id === $asset->business_id;
    }

    public function activate(User $user, FixedAsset $asset): bool
    {
        return $user->business_id === $asset->business_id;
    }

    public function dispose(User $user, FixedAsset $asset): bool
    {
        return $user->business_id === $asset->business_id;
    }

    public function generateSchedule(User $user, FixedAsset $asset): bool
    {
        return $user->business_id === $asset->business_id;
    }
}
