<?php

namespace App\Domains\Catalog\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;

class ProductUnit extends Model
{
    use HasFactory, HasUuids;

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
        'conversion_factor' => 'decimal:4',
        'purchase_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'minimum_price' => 'decimal:2',
        'is_base_unit' => 'boolean',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class);
    }

    public function branchPrices(): HasMany
    {
        return $this->hasMany(BranchProductPrice::class);
    }

    public function inventories(): HasMany
    {
        return $this->hasMany(\App\Domains\Inventory\Models\Inventory::class);
    }

    public function inventoryTransactions(): HasMany
    {
        return $this->hasMany(\App\Domains\Inventory\Models\InventoryTransaction::class);
    }

    public function purchaseInvoiceItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseInvoiceItem::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\OrderItem::class);
    }

    public function salesInvoiceItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesInvoiceItem::class);
    }

    public function cartItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\CartItem::class);
    }

    public function channels(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(\App\Domains\Sales\Models\Channel::class, 'product_channels', 'product_unit_id', 'channel_id')
                    ->withPivot('sale_price', 'is_enabled', 'display_order');
    }
}
