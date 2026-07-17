<?php

namespace Database\Factories\Domains\Inventory\Models;

use App\Domains\Inventory\Models\InventoryTransactionLine;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Core\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;

class InventoryTransactionLineFactory extends Factory
{
    protected $model = InventoryTransactionLine::class;

    public function definition(): array
    {
        return [
            'business_id' => Business::factory(),
            'inventory_transaction_id' => InventoryTransaction::factory(),
            'product_unit_id' => ProductUnit::factory(),
            'line_number' => 1,
            'quantity' => 10.000,
            'unit_cost' => 100.00,
        ];
    }
}
