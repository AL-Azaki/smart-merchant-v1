<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Unit extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'id',
        'business_id',
        'unit_name',
        'unit_symbol',
        'unit_description',
        'name',
        'short_name',
        'allow_decimal',
        'is_active',
        'revision',
        'deleted_at',
    ];

    public function getNameAttribute()
    {
        return $this->unit_name;
    }

    public function setNameAttribute($value): void
    {
        $this->attributes['unit_name'] = $value;
    }

    public function getShortNameAttribute()
    {
        return $this->unit_symbol;
    }

    public function setShortNameAttribute($value): void
    {
        $this->attributes['unit_symbol'] = $value;
    }

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }
}
