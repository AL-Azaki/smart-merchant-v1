<?php

namespace App\Domains\Purchasing\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Inventory\Models\Warehouse;

class PurchaseReturnItem extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // No timestamps in DB for this table

    protected $fillable = [
        'business_id',
        'purchase_return_id',
        'purchase_invoice_item_id',
        'warehouse_id',
        'quantity',
        'unit_price',
        'line_total',
        'base_line_total',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_price' => 'decimal:2',
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

    public function purchaseReturn(): BelongsTo
    {
        return $this->belongsTo(PurchaseReturn::class);
    }

    public function purchaseInvoiceItem(): BelongsTo
    {
        return $this->belongsTo(PurchaseInvoiceItem::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }
}
