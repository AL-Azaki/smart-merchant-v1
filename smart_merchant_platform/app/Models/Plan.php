<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Plan extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['plan_name', 'description', 'price_monthly', 'price_yearly', 'currency_id', 'features_json', 'is_active'];

    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }
}
