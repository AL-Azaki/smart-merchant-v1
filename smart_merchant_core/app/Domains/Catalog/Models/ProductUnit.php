<?php

namespace App\Domains\Catalog\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;

class ProductUnit extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'product_units';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
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
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_base_unit' => 'boolean',
        'conversion_factor' => 'decimal:4',
        'purchase_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'minimum_price' => 'decimal:2',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class, 'unit_id');
    }

    public function branchProductPrices(): HasMany
    {
        return $this->hasMany(BranchProductPrice::class, 'product_unit_id');
    }
}
