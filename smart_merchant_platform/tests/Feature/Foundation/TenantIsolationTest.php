<?php

namespace Tests\Feature\Foundation;

use App\Models\Business;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    public function test_business_cannot_access_another_business_products()
    {
        $businessA = Business::factory()->create();
        $productA = Product::factory()->create(['business_id' => $businessA->id]);

        $businessB = Business::factory()->create();

        // Using the tenant scope
        $businessA_Products = Product::forBusiness($businessA->id)->get();
        $this->assertTrue($businessA_Products->contains('id', $productA->id));

        $businessB_Products = Product::forBusiness($businessB->id)->get();
        $this->assertFalse($businessB_Products->contains('id', $productA->id));
    }
}
