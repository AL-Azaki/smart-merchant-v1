<?php

namespace App\Domains\Purchasing\Models;

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

class Supplier extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'supplier_name',
        'contact_person',
        'phone',
        'supplier_address',
        'default_currency_id',
        'payment_term_id',
        'payable_account_id',
        'credit_limit',
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

    public function payableAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class, 'payable_account_id');
    }

    public function purchaseInvoices(): HasMany
    {
        return $this->hasMany(PurchaseInvoice::class);
    }
}
