<?php

namespace Database\Factories;

use App\Models\Branch;
use App\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class BranchFactory extends Factory
{
    protected $model = Branch::class;

    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'branch_name' => $this->faker->company(),
            'branch_code' => Str::random(5),
            'is_active' => true,
            'revision' => 1,
        ];
    }
}
