<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Plan extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'plan_name',
        'currency_id',
        'billing_cycle',
        'duration_months',
        'price',
        'max_businesses',
        'max_branches',
        'max_users',
        'description',
        'price_monthly',
        'price_yearly',
        'features_json',
        'is_active',
    ];

    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }
}
