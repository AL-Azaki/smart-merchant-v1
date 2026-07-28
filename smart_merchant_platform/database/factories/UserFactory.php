<?php

namespace Database\Factories;

use App\Models\Account;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

class UserFactory extends Factory
{
    protected $model = User::class;

    protected static ?string $password;

    public function definition()
    {
        return [
            'account_id' => Account::factory(),
            'username' => $this->faker->unique()->userName(),
            'email' => $this->faker->unique()->safeEmail(),
            'password_hash' => static::$password ??= Hash::make('password'),
            'full_name' => $this->faker->name(),
            'is_active' => true,
        ];
    }
}
