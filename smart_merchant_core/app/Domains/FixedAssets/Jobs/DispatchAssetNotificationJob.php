<?php

namespace App\Domains\FixedAssets\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Models\DepreciationSchedule;
use App\Domains\FixedAssets\Services\Integration\Notification\AssetNotificationBuilder;

class DispatchAssetNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $assetId;
    public ?string $scheduleId;
    public string $eventName;

    public function __construct(string $assetId, ?string $scheduleId, string $eventName)
    {
        $this->assetId = $assetId;
        $this->scheduleId = $scheduleId;
        $this->eventName = $eventName;
    }

    public function handle(AssetNotificationBuilder $builder): void
    {
        $asset = FixedAsset::find($this->assetId);
        if (!$asset) {
            return;
        }

        if ($this->eventName === 'DepreciationPosted' && $this->scheduleId) {
            $schedule = DepreciationSchedule::find($this->scheduleId);
            if ($schedule) {
                $builder->buildDepreciationPostedNotification($asset, $schedule);
            }
        } elseif ($this->eventName === 'AssetDisposed') {
            $builder->buildAssetDisposedNotification($asset);
        }
    }
}
