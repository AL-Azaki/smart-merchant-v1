<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Finance\Models\Tax;

class SalesInvoiceItem extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // No timestamps in DB for this table

    protected $fillable = [
        'business_id',
        'sales_invoice_id',
        'order_item_id',
        'product_unit_id',
        'warehouse_id',
        'tax_id',
        'quantity',
        'unit_price',
        'cost_price',
        'discount',
        'tax',
        'line_total',
        'cost_total',
        'base_line_total',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_price' => 'decimal:2',
        'cost_price' => 'decimal:2',
        'discount' => 'decimal:2',
        'tax' => 'decimal:2',
        'line_total' => 'decimal:2',
        'cost_total' => 'decimal:2',
        'base_line_total' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function salesInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class);
    }

    public function orderItem(): BelongsTo
    {
        return $this->belongsTo(OrderItem::class);
    }

    public function productUnit(): BelongsTo
    {
        return $this->belongsTo(ProductUnit::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function tax(): BelongsTo
    {
        return $this->belongsTo(Tax::class);
    }

    public function returnedItems(): HasMany
    {
        return $this->hasMany(SalesReturnItem::class);
    }
}
