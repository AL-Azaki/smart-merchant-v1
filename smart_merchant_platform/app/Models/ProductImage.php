<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductImage extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['business_id', 'product_id', 'image_path', 'is_primary', 'sort_order', 'revision'];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }
}
