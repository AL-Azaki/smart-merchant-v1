<?php

namespace App\Domains\FixedAssets\Services\Integration\GeneralLedger;

use App\Domains\FixedAssets\Models\FixedAsset;

class AssetDisposalPostingBuilder
{
    /**
     * Build a PostingRequestDTO payload for an asset disposal.
     * Removes the asset cost and accumulated depreciation from the balance sheet,
     * and recognizes any gain or loss on disposal.
     */
    public function build(FixedAsset $asset, array $accountConfig, float $accumulatedDepreciation, float $disposalProceeds = 0): array
    {
        $netBookValue = (float) $asset->base_acquisition_cost - $accumulatedDepreciation;
        $gainOrLoss = $disposalProceeds - $netBookValue;

        $lines = [
            // Remove accumulated depreciation (debit to reverse the credit balance)
            [
                'account_id' => $accountConfig['accumulated_depreciation_account_id'],
                'debit_amount' => $accumulatedDepreciation,
                'credit_amount' => 0,
                'description' => "Disposal - Remove accumulated depreciation: {$asset->asset_code}",
            ],
            // Remove asset cost (credit to reverse the debit balance)
            [
                'account_id' => $accountConfig['asset_account_id'],
                'debit_amount' => 0,
                'credit_amount' => (float) $asset->base_acquisition_cost,
                'description' => "Disposal - Remove asset cost: {$asset->asset_code}",
            ],
        ];

        // Record disposal proceeds if any
        if ($disposalProceeds > 0) {
            $lines[] = [
                'account_id' => $accountConfig['disposal_proceeds_account_id'] ?? $accountConfig['asset_account_id'],
                'debit_amount' => $disposalProceeds,
                'credit_amount' => 0,
                'description' => "Disposal proceeds: {$asset->asset_code}",
            ];
        }

        // Record gain or loss
        if ($gainOrLoss > 0) {
            $lines[] = [
                'account_id' => $accountConfig['gain_on_disposal_account_id'] ?? $accountConfig['asset_account_id'],
                'debit_amount' => 0,
                'credit_amount' => $gainOrLoss,
                'description' => "Gain on disposal: {$asset->asset_code}",
            ];
        } elseif ($gainOrLoss < 0) {
            $lines[] = [
                'account_id' => $accountConfig['loss_on_disposal_account_id'] ?? $accountConfig['asset_account_id'],
                'debit_amount' => abs($gainOrLoss),
                'credit_amount' => 0,
                'description' => "Loss on disposal: {$asset->asset_code}",
            ];
        }

        return [
            'business_id' => $asset->business_id,
            'source_domain' => 'FixedAssets',
            'source_entity' => 'FixedAsset',
            'source_entity_id' => $asset->id,
            'posting_date' => now()->toDateString(),
            'description' => "Asset Disposal: {$asset->asset_name} ({$asset->asset_code})",
            'currency_id' => $asset->currency_id,
            'lines' => $lines,
        ];
    }
}
