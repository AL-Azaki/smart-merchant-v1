<?php

namespace App\Domains\Purchasing\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\Warehouse;

class PurchaseInvoice extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'branch_id',
        'supplier_id',
        'warehouse_id',
        'invoice_number',
        'purchase_date',
        'due_date',
        'currency_id',
        'exchange_rate',
        'sub_total',
        'discount_total',
        'tax_total',
        'grand_total',
        'base_sub_total',
        'base_discount_total',
        'base_tax_total',
        'base_grand_total',
        'payment_status',
        'status',
        'notes',
        'created_by',
        'posted_by',
        'posted_at',
        'reversed_by',
        'reversed_at',
    ];

    protected $casts = [
        'purchase_date' => 'datetime',
        'due_date' => 'datetime',
        'exchange_rate' => 'decimal:8',
        'sub_total' => 'decimal:2',
        'discount_total' => 'decimal:2',
        'tax_total' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'base_sub_total' => 'decimal:2',
        'base_discount_total' => 'decimal:2',
        'base_tax_total' => 'decimal:2',
        'base_grand_total' => 'decimal:2',
        'posted_at' => 'datetime',
        'reversed_at' => 'datetime',
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

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
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

    public function items(): HasMany
    {
        return $this->hasMany(PurchaseInvoiceItem::class);
    }

    public function returns(): HasMany
    {
        return $this->hasMany(PurchaseReturn::class);
    }
}
