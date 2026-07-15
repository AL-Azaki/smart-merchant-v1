<?php

namespace App\Domains\Catalog\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Unit extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'unit_name',
        'unit_symbol',
        'unit_description',
    ];

    /**
     * Relationships
     */
    public function productUnits(): HasMany
    {
        return $this->hasMany(ProductUnit::class);
    }
}
