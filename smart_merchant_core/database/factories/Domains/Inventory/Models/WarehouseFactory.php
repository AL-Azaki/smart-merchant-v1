<?php

namespace Database\Factories\Domains\Inventory\Models;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use Illuminate\Database\Eloquent\Factories\Factory;

class WarehouseFactory extends Factory
{
    protected $model = Warehouse::class;

    public function definition(): array
    {
        return [
            'business_id' => Business::factory(),
            'branch_id' => Branch::factory(),
            'warehouse_name' => $this->faker->company . ' Warehouse',
            'warehouse_code' => 'WH-' . strtoupper($this->faker->unique()->lexify('????')),
            'address' => $this->faker->address,
            'is_default' => false,
            'is_active' => true,
        ];
    }
}
