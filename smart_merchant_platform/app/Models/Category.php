<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Category extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'id',
        'business_id',
        'parent_id',
        'category_name',
        'category_code',
        'name',
        'slug',
        'description',
        'image_path',
        'sort_order',
        'is_active',
        'revision',
        'deleted_at',
    ];

    public function getNameAttribute()
    {
        return $this->category_name;
    }

    public function setNameAttribute($value): void
    {
        $this->attributes['category_name'] = $value;
    }

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    public function parent()
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    public function children()
    {
        return $this->hasMany(Category::class, 'parent_id');
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
