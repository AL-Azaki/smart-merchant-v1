<?php

namespace Database\Factories;

use App\Models\OrderItem;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<OrderItem>
 */
class OrderItemFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'business_id' => \App\Models\Business::factory(),
            'order_id' => \App\Models\Order::factory(),
            'product_unit_id' => \App\Models\ProductUnit::factory(),
            'quantity' => $this->faker->randomFloat(3, 1, 10),
            'unit_price' => $this->faker->randomFloat(2, 10, 100),
            'line_total' => $this->faker->randomFloat(2, 10, 100),
        ];
    }
}
