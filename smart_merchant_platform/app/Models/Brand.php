<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Brand extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'id',
        'business_id',
        'brand_name',
        'name',
        'slug',
        'description',
        'logo_path',
        'is_active',
        'revision',
        'deleted_at',
    ];

    public function getNameAttribute()
    {
        return $this->brand_name;
    }

    public function setNameAttribute($value): void
    {
        $this->attributes['brand_name'] = $value;
    }

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }
}
