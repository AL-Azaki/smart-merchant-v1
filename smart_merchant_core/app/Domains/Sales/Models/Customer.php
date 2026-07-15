<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Currency;
use App\Domains\Finance\Models\PaymentTerm;
use App\Domains\Finance\Models\ChartOfAccount;

class Customer extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'customer_name',
        'phone',
        'email',
        'address',
        'credit_limit',
        'default_currency_id',
        'payment_term_id',
        'receivable_account_id',
        'opening_balance',
        'opening_balance_type',
        'opening_balance_date',
        'is_active',
    ];

    protected $casts = [
        'credit_limit' => 'decimal:2',
        'opening_balance' => 'decimal:2',
        'opening_balance_date' => 'date',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function defaultCurrency(): BelongsTo
    {
        return $this->belongsTo(Currency::class, 'default_currency_id');
    }

    public function paymentTerm(): BelongsTo
    {
        return $this->belongsTo(PaymentTerm::class, 'payment_term_id');
    }

    public function receivableAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class, 'receivable_account_id');
    }

    public function salesInvoices(): HasMany
    {
        return $this->hasMany(SalesInvoice::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function carts(): HasMany
    {
        return $this->hasMany(Cart::class);
    }
}
