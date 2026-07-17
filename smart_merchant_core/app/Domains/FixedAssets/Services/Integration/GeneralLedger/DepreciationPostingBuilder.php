<?php

namespace App\Domains\FixedAssets\Services\Integration\GeneralLedger;

use App\Domains\FixedAssets\Models\DepreciationSchedule;
use App\Domains\FixedAssets\Models\FixedAsset;

class DepreciationPostingBuilder
{
    /**
     * Build a PostingRequestDTO payload for a single depreciation schedule period.
     * This does NOT create a Journal Entry. It builds the payload for the GL domain to process.
     */
    public function build(FixedAsset $asset, DepreciationSchedule $schedule, array $accountConfig): array
    {
        return [
            'business_id' => $asset->business_id,
            'source_domain' => 'FixedAssets',
            'source_entity' => 'DepreciationSchedule',
            'source_entity_id' => $schedule->id,
            'posting_date' => $schedule->scheduled_posting_date->toDateString(),
            'description' => "Depreciation: {$asset->asset_name} ({$asset->asset_code}) - Period {$schedule->depreciation_period}",
            'currency_id' => $asset->currency_id,
            'lines' => [
                [
                    'account_id' => $accountConfig['depreciation_expense_account_id'],
                    'debit_amount' => $schedule->base_depreciation_amount,
                    'credit_amount' => 0,
                    'description' => "Depreciation expense - {$asset->asset_code}",
                ],
                [
                    'account_id' => $accountConfig['accumulated_depreciation_account_id'],
                    'debit_amount' => 0,
                    'credit_amount' => $schedule->base_depreciation_amount,
                    'description' => "Accumulated depreciation - {$asset->asset_code}",
                ],
            ],
        ];
    }
}
