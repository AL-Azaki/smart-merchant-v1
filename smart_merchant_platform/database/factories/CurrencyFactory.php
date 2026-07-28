<?php

namespace Database\Factories;

use App\Models\Currency;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class CurrencyFactory extends Factory
{
    protected $model = Currency::class;

    public function definition()
    {
        return [
            'currency_code' => strtoupper(Str::random(3)),
            'currency_name_en' => $this->faker->currencyCode(),
            'currency_name_ar' => 'Arabic Name',
            'currency_symbol' => '$',
            'is_active' => true,
        ];
    }
}
