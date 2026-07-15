<?php

namespace App\Domains\Inventory\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Catalog\Models\ProductUnit;

class InventoryTransferItem extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // The migration only has quantity and unit_cost without timestamps

    protected $fillable = [
        'business_id',
        'transfer_id',
        'product_unit_id',
        'quantity',
        'unit_cost',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_cost' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function transfer(): BelongsTo
    {
        return $this->belongsTo(InventoryTransfer::class, 'transfer_id');
    }

    public function productUnit(): BelongsTo
    {
        return $this->belongsTo(ProductUnit::class);
    }
}
