<?php

namespace Database\Factories\Domains\Inventory\Models;

use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Core\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;

class InventoryFactory extends Factory
{
    protected $model = Inventory::class;

    public function definition(): array
    {
        return [
            'business_id' => Business::factory(),
            'warehouse_id' => Warehouse::factory(),
            'product_unit_id' => ProductUnit::factory(),
            'quantity' => 0.000,
            'average_cost' => 0.00,
            'alert_quantity' => 0.000,
        ];
    }
}
