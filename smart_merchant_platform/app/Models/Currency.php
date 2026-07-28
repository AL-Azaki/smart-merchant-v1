<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Currency extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false;

    protected $fillable = ['currency_code', 'currency_name_ar', 'currency_name_en', 'currency_symbol', 'decimal_places', 'exchange_rate', 'is_base_currency', 'is_active'];
}
