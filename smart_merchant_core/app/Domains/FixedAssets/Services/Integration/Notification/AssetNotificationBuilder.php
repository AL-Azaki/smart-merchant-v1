<?php

namespace App\Domains\FixedAssets\Services\Integration\Notification;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Models\DepreciationSchedule;

class AssetNotificationBuilder
{
    public function buildDepreciationPostedNotification(FixedAsset $asset, DepreciationSchedule $schedule): array
    {
        return [
            'business_id' => $asset->business_id,
            'module' => 'FixedAssets',
            'entity_type' => 'DepreciationSchedule',
            'entity_id' => $schedule->id,
            'title' => 'Depreciation Posted',
            'message' => "Depreciation for asset '{$asset->asset_name}' ({$asset->asset_code}) period {$schedule->depreciation_period} has been posted.",
            'level' => 'info',
            'metadata' => [
                'asset_id' => $asset->id,
                'asset_code' => $asset->asset_code,
                'period' => $schedule->depreciation_period,
                'amount' => $schedule->base_depreciation_amount,
                'remaining_book_value' => $schedule->base_remaining_book_value,
            ],
        ];
    }

    public function buildAssetDisposedNotification(FixedAsset $asset): array
    {
        return [
            'business_id' => $asset->business_id,
            'module' => 'FixedAssets',
            'entity_type' => 'FixedAsset',
            'entity_id' => $asset->id,
            'title' => 'Asset Disposed',
            'message' => "Fixed asset '{$asset->asset_name}' ({$asset->asset_code}) has been disposed.",
            'level' => 'warning',
            'metadata' => [
                'asset_id' => $asset->id,
                'asset_code' => $asset->asset_code,
                'asset_name' => $asset->asset_name,
            ],
        ];
    }
}
