<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Catalog\Models\ProductUnit;

class CartItem extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // No timestamps in DB for this table

    protected $fillable = [
        'business_id',
        'cart_id',
        'product_unit_id',
        'quantity',
        'unit_price',
        'tax',
        'line_total',
        'base_line_total',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_price' => 'decimal:2',
        'tax' => 'decimal:2',
        'line_total' => 'decimal:2',
        'base_line_total' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function cart(): BelongsTo
    {
        return $this->belongsTo(Cart::class);
    }

    public function productUnit(): BelongsTo
    {
        return $this->belongsTo(ProductUnit::class);
    }
}
