<?php

namespace App\Domains\FixedAssets\Listeners;

use App\Domains\FixedAssets\Events\DepreciationSchedulePosted;
use App\Domains\FixedAssets\Events\FixedAssetDisposed;
use App\Domains\FixedAssets\Jobs\DispatchAssetNotificationJob;
use Illuminate\Events\Dispatcher;

class FixedAssetsEventSubscriber
{
    public function subscribe(Dispatcher $events): void
    {
        $events->listen(DepreciationSchedulePosted::class, [self::class, 'onDepreciationPosted']);
        $events->listen(FixedAssetDisposed::class, [self::class, 'onAssetDisposed']);
    }

    public function onDepreciationPosted(DepreciationSchedulePosted $event): void
    {
        DispatchAssetNotificationJob::dispatch(
            $event->schedule->fixed_asset_id,
            $event->schedule->id,
            'DepreciationPosted'
        );
    }

    public function onAssetDisposed(FixedAssetDisposed $event): void
    {
        DispatchAssetNotificationJob::dispatch(
            $event->asset->id,
            null,
            'AssetDisposed'
        );
    }
}
