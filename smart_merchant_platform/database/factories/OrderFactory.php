<?php

namespace Database\Factories;

use App\Models\Branch;
use App\Models\Business;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\Order;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'branch_id' => Branch::factory(),
            'channel_id' => Channel::factory(),
            'currency_id' => Currency::factory(),
            'order_number' => 'ORD-'.strtoupper(Str::random(6)),
            'revision' => 1,
        ];
    }
}
