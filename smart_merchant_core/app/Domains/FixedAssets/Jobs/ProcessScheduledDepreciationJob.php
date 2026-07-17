<?php

namespace App\Domains\FixedAssets\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\FixedAssets\Models\DepreciationSchedule;
use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Services\Integration\GeneralLedger\DepreciationPostingBuilder;
use App\Domains\FixedAssets\Services\Integration\FinancialClosing\DepreciationPostingAuthorizationService;
use App\Domains\FixedAssets\Services\Integration\Finance\AssetAccountResolutionService;
use App\Domains\FixedAssets\Events\DepreciationSchedulePosted;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessScheduledDepreciationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $scheduleId;

    public function __construct(string $scheduleId)
    {
        $this->scheduleId = $scheduleId;
    }

    public function handle(
        DepreciationPostingBuilder $postingBuilder,
        DepreciationPostingAuthorizationService $authService,
        AssetAccountResolutionService $accountService
    ): void {
        $schedule = DepreciationSchedule::with('fixedAsset')->find($this->scheduleId);

        if (!$schedule || $schedule->status !== 'Ready') {
            Log::info("Depreciation schedule [{$this->scheduleId}] is not in Ready status. Skipping.");
            return;
        }

        $asset = $schedule->fixedAsset;

        try {
            // Step 1: Validate accounting period is open
            $authService->authorize($asset->business_id, $schedule->scheduled_posting_date->toDateString());

            // Step 2: Resolve account configuration
            $accountConfig = $accountService->resolve($asset->business_id, $asset->asset_category_id);

            // Step 3: Build posting request payload
            $postingPayload = $postingBuilder->build($asset, $schedule, $accountConfig);

            // Step 4: Mark schedule as posted within a transaction
            DB::transaction(function () use ($schedule, $postingPayload) {
                $schedule->update(['status' => 'Posted']);

                // The posting payload would be dispatched to the GL domain's posting engine.
                // In production: GLPostingService::post($postingPayload);
            });

            // Step 5: Dispatch domain event AFTER successful commit
            DepreciationSchedulePosted::dispatch($schedule->fresh());

        } catch (\Exception $e) {
            Log::error("Depreciation posting failed for schedule [{$this->scheduleId}]: {$e->getMessage()}");
            throw $e;
        }
    }
}
