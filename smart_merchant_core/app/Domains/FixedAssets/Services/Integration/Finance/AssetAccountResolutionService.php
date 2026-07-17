<?php

namespace App\Domains\FixedAssets\Services\Integration\Finance;

use RuntimeException;

class AssetAccountResolutionService
{
    /**
     * Resolve the full accounting configuration for a fixed asset based on its category or explicit mapping.
     * Returns the account IDs required for GL posting builders.
     *
     * This service reads Finance Foundation configuration only.
     * It does NOT execute any accounting logic.
     */
    public function resolve(string $businessId, ?string $assetCategoryId = null): array
    {
        // In a production implementation, this would query the Finance domain's
        // asset category → account mapping table. For now, we resolve based on
        // a configuration lookup pattern.

        $config = $this->loadCategoryConfig($businessId, $assetCategoryId);

        if (empty($config['asset_account_id'])) {
            throw new RuntimeException("Asset account not configured for business [{$businessId}].");
        }

        if (empty($config['depreciation_expense_account_id'])) {
            throw new RuntimeException("Depreciation expense account not configured for business [{$businessId}].");
        }

        if (empty($config['accumulated_depreciation_account_id'])) {
            throw new RuntimeException("Accumulated depreciation account not configured for business [{$businessId}].");
        }

        return $config;
    }

    private function loadCategoryConfig(string $businessId, ?string $assetCategoryId): array
    {
        // Placeholder: In production, this queries the finance_asset_category_mappings table
        // or a system_settings entry scoped to the business.
        // Returns the mapping of category to GL accounts.
        return [
            'asset_account_id' => null,
            'depreciation_expense_account_id' => null,
            'accumulated_depreciation_account_id' => null,
            'gain_on_disposal_account_id' => null,
            'loss_on_disposal_account_id' => null,
            'disposal_proceeds_account_id' => null,
        ];
    }
}
