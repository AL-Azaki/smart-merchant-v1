<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ProductUnit extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'id',
        'business_id',
        'product_id',
        'unit_id',
        'sku',
        'barcode',
        'conversion_factor',
        'purchase_price',
        'selling_price',
        'minimum_price',
        'is_base_unit',
        'is_active',
        'revision',
        'deleted_at',
    ];

    protected $casts = [
        'is_base_unit' => 'boolean',
        'is_active' => 'boolean',
        'conversion_factor' => 'decimal:4',
        'purchase_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'minimum_price' => 'decimal:2',
    ];

    /**
     * Backward-compatibility accessor for legacy calls referencing price.
     */
    public function getPriceAttribute()
    {
        return $this->selling_price;
    }

    /**
     * Backward-compatibility mutator for legacy calls referencing price.
     */
    public function setPriceAttribute($value): void
    {
        $this->attributes['selling_price'] = $value;
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class);
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }

    public function scopeEligibleForStorefront($query, $businessId = null)
    {
        if ($businessId) {
            $query->where('business_id', $businessId);
        }

        return $query->where('is_active', true)
            ->whereHas('product', function ($q) use ($businessId) {
                $q->publishedToStorefront($businessId);
            });
    }
}
