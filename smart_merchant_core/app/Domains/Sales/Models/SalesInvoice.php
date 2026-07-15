<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;

class SalesInvoice extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'branch_id',
        'customer_id',
        'invoice_number',
        'invoice_date',
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
    ];

    protected $casts = [
        'invoice_date' => 'datetime',
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

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function items(): HasMany
    {
        return $this->hasMany(SalesInvoiceItem::class);
    }

    public function returns(): HasMany
    {
        return $this->hasMany(SalesReturn::class);
    }
}
