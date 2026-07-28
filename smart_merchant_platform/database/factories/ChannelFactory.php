<?php

namespace Database\Factories;

use App\Models\Business;
use App\Models\Channel;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class ChannelFactory extends Factory
{
    protected $model = Channel::class;

    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'channel_name' => 'Storefront',
            'channel_code' => 'storefront-'.Str::random(5),
            'channel_type' => 'Ecommerce',
            'is_active' => true,
        ];
    }
}
