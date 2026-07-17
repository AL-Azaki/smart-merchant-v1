<?php

namespace Database\Factories\Domains\Inventory\Models;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Core\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class InventoryTransactionFactory extends Factory
{
    protected $model = InventoryTransaction::class;

    public function definition(): array
    {
        return [
            'business_id' => Business::factory(),
            'branch_id' => Branch::factory(),
            'warehouse_id' => Warehouse::factory(),
            'transaction_type' => 'Opening Balance',
            'movement_direction' => 'IN',
            'status' => 'Draft',
            'transaction_date' => now(),
            'created_by' => User::factory(),
        ];
    }
}
