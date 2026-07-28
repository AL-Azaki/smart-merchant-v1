<?php

namespace Database\Factories;

use App\Models\Account;
use App\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;

class BusinessFactory extends Factory
{
    protected $model = Business::class;

    public function definition()
    {
        return [
            'account_id' => Account::factory(),
            'business_name' => $this->faker->company(),
            'business_type' => 'Retail',
            'status' => 'Active',
            'revision' => 1,
        ];
    }
}
