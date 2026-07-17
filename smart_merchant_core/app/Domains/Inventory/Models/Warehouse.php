<?php

namespace App\Domains\Inventory\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;

class Warehouse extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'branch_id',
        'warehouse_name',
        'warehouse_code',
        'address',
        'is_default',
        'is_active',
    ];

    protected $casts = [
        'is_default' => 'boolean',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    public function inventories(): HasMany
    {
        return $this->hasMany(Inventory::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(InventoryTransaction::class);
    }

    public function transfersFrom(): HasMany
    {
        return $this->hasMany(InventoryTransfer::class, 'from_warehouse_id');
    }

    public function transfersTo(): HasMany
    {
        return $this->hasMany(InventoryTransfer::class, 'to_warehouse_id');
    }

    public function purchaseInvoices(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseInvoice::class);
    }

    public function purchaseInvoiceItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseInvoiceItem::class);
    }

    public function purchaseReturnItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseReturnItem::class);
    }

    public function salesInvoiceItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesInvoiceItem::class);
    }

    public function salesReturnItems(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesReturnItem::class);
    }
}
