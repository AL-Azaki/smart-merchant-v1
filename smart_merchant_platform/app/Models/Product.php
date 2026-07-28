<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['business_id', 'category_id', 'brand_id', 'tax_id', 'product_type', 'product_code', 'product_name', 'description', 'is_active', 'revision'];

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function brand()
    {
        return $this->belongsTo(Brand::class);
    }

    public function units()
    {
        return $this->hasMany(ProductUnit::class);
    }

    public function images()
    {
        return $this->hasMany(ProductImage::class);
    }

    public function channels()
    {
        return $this->belongsToMany(Channel::class, 'product_channels');
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }
}
