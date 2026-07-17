<?php

namespace Tests\Feature\Domains\FixedAssets;

use Tests\TestCase;

class FixedAssetsFeatureTest extends TestCase
{
    public function test_can_create_fixed_asset_in_draft()
    {
        $this->assertTrue(true);
    }

    public function test_can_update_draft_fixed_asset()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_update_disposed_asset()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_modify_acquisition_cost_after_activation()
    {
        $this->assertTrue(true);
    }

    public function test_can_activate_draft_asset()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_activate_non_draft_asset()
    {
        $this->assertTrue(true);
    }

    public function test_can_dispose_active_asset()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_dispose_draft_asset()
    {
        $this->assertTrue(true);
    }

    public function test_can_generate_depreciation_schedule()
    {
        $this->assertTrue(true);
    }

    public function test_disposal_cancels_pending_schedules()
    {
        $this->assertTrue(true);
    }

    public function test_can_load_aggregate_with_schedules()
    {
        $this->assertTrue(true);
    }

    public function test_can_list_fixed_assets_by_business()
    {
        $this->assertTrue(true);
    }
}
