<?php

namespace App\Domains\Inventory\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Core\Models\Business;

class Inventory extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'warehouse_id',
        'product_unit_id',
        'quantity',
        'average_cost',
        'alert_quantity',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'average_cost' => 'decimal:2',
        'alert_quantity' => 'decimal:3',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function productUnit(): BelongsTo
    {
        return $this->belongsTo(ProductUnit::class);
    }
}
