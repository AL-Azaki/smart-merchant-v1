<?php

namespace App\Domains\Inventory\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\User;

class InventoryTransaction extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'warehouse_id',
        'transaction_type',
        'status',
        'reference_type',
        'reference_id',
        'transaction_date',
        'notes',
        'created_by',
        'posted_by',
        'posted_at',
        'reversed_by',
        'reversed_at',
    ];

    protected $casts = [
        'transaction_date' => 'datetime',
        'posted_at' => 'datetime',
        'reversed_at' => 'datetime',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function postedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'posted_by');
    }

    public function reversedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reversed_by');
    }

    public function lines(): HasMany
    {
        return $this->hasMany(InventoryTransactionLine::class, 'inventory_transaction_id');
    }
}
