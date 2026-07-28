<?php

namespace Database\Factories;

use App\Models\Account;
use Illuminate\Database\Eloquent\Factories\Factory;

class AccountFactory extends Factory
{
    protected $model = Account::class;

    public function definition()
    {
        return [
            'name' => $this->faker->company(),
            'owner_name' => $this->faker->name(),
            'email' => $this->faker->unique()->safeEmail(),
            'status' => 'Active',
        ];
    }
}
