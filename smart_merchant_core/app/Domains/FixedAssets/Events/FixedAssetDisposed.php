<?php

namespace App\Domains\FixedAssets\Events;

use App\Domains\FixedAssets\Models\FixedAsset;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class FixedAssetDisposed
{
    use Dispatchable, SerializesModels;

    public FixedAsset $asset;

    public function __construct(FixedAsset $asset)
    {
        $this->asset = $asset;
    }
}
