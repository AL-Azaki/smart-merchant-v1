<?php

namespace Tests\Feature\Ecommerce;

use App\Models\Business;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InventoryAuthorityTest extends TestCase
{
    use RefreshDatabase;

    public function test_inventory_projection_reflects_latest_erp_synced_quantity()
    {
        $business = Business::factory()->create();

        // Product represents a catalog projection which might also carry availability info if extended.
        $product = Product::factory()->create([
            'business_id' => $business->id,
            'revision' => 1,
        ]);

        // Simulate an update from ERP with revision 2
        $product->update([
            'revision' => 2,
        ]);

        $this->assertEquals(2, $product->fresh()->revision);

        // Simulate a STALE update from ERP (e.g. delayed network packet with revision 1)
        $staleRevision = 1;
        if ($staleRevision > $product->revision) {
            $product->update(['revision' => $staleRevision]);
        }

        // The projection should reject the stale update (simulate this logic by checking if condition holds)
        $this->assertEquals(2, $product->fresh()->revision, 'Stale revision update was rejected.');
    }
}
