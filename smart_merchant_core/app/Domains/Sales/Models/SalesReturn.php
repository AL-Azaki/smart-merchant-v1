<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;

class SalesReturn extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'branch_id',
        'sales_invoice_id',
        'return_number',
        'return_date',
        'currency_id',
        'exchange_rate',
        'total_amount',
        'base_total_amount',
        'status',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'return_date' => 'datetime',
        'exchange_rate' => 'decimal:8',
        'total_amount' => 'decimal:2',
        'base_total_amount' => 'decimal:2',
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

    public function salesInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class);
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
        return $this->hasMany(SalesReturnItem::class);
    }
}
