<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Inventory\Models\Warehouse;

class SalesReturnItem extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // No timestamps in DB for this table

    protected $fillable = [
        'business_id',
        'sales_return_id',
        'sales_invoice_item_id',
        'warehouse_id',
        'quantity',
        'unit_price',
        'cost_price',
        'total_price',
        'cost_total',
        'base_total_price',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_price' => 'decimal:2',
        'cost_price' => 'decimal:2',
        'total_price' => 'decimal:2',
        'cost_total' => 'decimal:2',
        'base_total_price' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function salesReturn(): BelongsTo
    {
        return $this->belongsTo(SalesReturn::class);
    }

    public function salesInvoiceItem(): BelongsTo
    {
        return $this->belongsTo(SalesInvoiceItem::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }
}
