<?php

namespace Database\Factories;

use App\Models\Business;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class ProductFactory extends Factory
{
    protected $model = Product::class;

    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'product_code' => Str::random(10),
            'product_name' => $this->faker->word(),
            'is_active' => true,
            'revision' => 1,
        ];
    }
}
