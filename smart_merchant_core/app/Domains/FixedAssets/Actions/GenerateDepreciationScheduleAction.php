<?php

namespace App\Domains\FixedAssets\Actions;

use App\Domains\FixedAssets\Models\FixedAsset;
use App\Domains\FixedAssets\Models\DepreciationSchedule;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Carbon\Carbon;

class GenerateDepreciationScheduleAction
{
    private FixedAssetRepositoryInterface $repository;

    public function __construct(FixedAssetRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $assetId, string $generatedBy): FixedAsset
    {
        return DB::transaction(function () use ($assetId, $generatedBy) {
            $asset = $this->repository->loadAggregate($assetId);

            if (!in_array($asset->status, ['Active', 'Depreciating'])) {
                throw new RuntimeException("Depreciation schedule can only be generated for Active or Depreciating assets.");
            }

            // Prevent regenerating if posted schedules already exist
            $hasPostedSchedules = $asset->depreciationSchedules()->where('status', 'Posted')->exists();
            if ($hasPostedSchedules) {
                // Cancel only pending/ready, then regenerate remaining
                $asset->depreciationSchedules()
                    ->whereIn('status', ['Pending', 'Ready'])
                    ->update([
                        'status' => 'Cancelled',
                        'updated_by' => $generatedBy,
                    ]);
            } else {
                // No posted schedules: cancel all existing and regenerate from scratch
                $asset->depreciationSchedules()
                    ->whereIn('status', ['Pending', 'Ready'])
                    ->update([
                        'status' => 'Cancelled',
                        'updated_by' => $generatedBy,
                    ]);
            }

            $depreciableBase = (float) $asset->base_acquisition_cost - (float) $asset->base_residual_value;
            if ($depreciableBase <= 0) {
                throw new RuntimeException("Depreciable base must be greater than zero.");
            }

            $usefulLife = $asset->useful_life; // in months
            $periodicDepreciation = round($depreciableBase / $usefulLife, 2);
            $startDate = Carbon::parse($asset->depreciation_start_date);

            // Determine how many periods have already been posted
            $postedCount = $asset->depreciationSchedules()->where('status', 'Posted')->count();
            $postedAccumulated = (float) $asset->depreciationSchedules()
                ->where('status', 'Posted')
                ->sum('base_depreciation_amount');

            $accumulatedDepreciation = $postedAccumulated;
            $remainingBookValue = (float) $asset->base_acquisition_cost - $accumulatedDepreciation;

            for ($period = $postedCount + 1; $period <= $usefulLife; $period++) {
                $scheduledDate = $startDate->copy()->addMonths($period - 1)->endOfMonth();

                // Last period adjustment to prevent rounding errors
                $amount = $periodicDepreciation;
                if ($period === $usefulLife) {
                    $amount = $remainingBookValue - (float) $asset->base_residual_value;
                }

                $accumulatedDepreciation += $amount;
                $remainingBookValue = (float) $asset->base_acquisition_cost - $accumulatedDepreciation;

                DepreciationSchedule::create([
                    'business_id' => $asset->business_id,
                    'fixed_asset_id' => $asset->id,
                    'depreciation_period' => $period,
                    'scheduled_posting_date' => $scheduledDate->toDateString(),
                    'depreciation_amount' => $amount,
                    'base_depreciation_amount' => $amount,
                    'accumulated_depreciation' => $accumulatedDepreciation,
                    'base_accumulated_depreciation' => $accumulatedDepreciation,
                    'remaining_book_value' => $remainingBookValue,
                    'base_remaining_book_value' => $remainingBookValue,
                    'status' => 'Pending',
                    'created_by' => $generatedBy,
                ]);
            }

            // Transition asset to Depreciating if it was Active
            if ($asset->status === 'Active') {
                $this->repository->update($asset, [
                    'status' => 'Depreciating',
                    'updated_by' => $generatedBy,
                ]);
            }

            return $this->repository->loadAggregate($assetId);
        });
    }
}
