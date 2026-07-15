<?php

namespace App\Domains\Core\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Plan;
use App\Domains\Finance\Models\ChartOfAccount;

class Currency extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'currency_code',
        'currency_name_ar',
        'currency_name_en',
        'currency_symbol',
        'decimal_places',
        'exchange_rate',
        'is_base_currency',
        'is_active',
    ];

    protected $casts = [
        'decimal_places' => 'integer',
        'exchange_rate' => 'decimal:8',
        'is_base_currency' => 'boolean',
        'is_active' => 'boolean',
    ];

    // Disable default timestamps if they are not exactly created_at/updated_at. 
    // We have them in this table implicitly? No, wait. In the migration for currencies we didn't add $table->timestamps()!
    // Let me check migration 000001. Ah, for `currencies` I didn't add timestamps. 
    public $timestamps = false;

    /**
     * Relationships
     */
    public function plans(): HasMany
    {
        return $this->hasMany(Plan::class);
    }

    public function suppliers(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\Supplier::class, 'default_currency_id');
    }

    public function purchaseInvoices(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseInvoice::class);
    }

    public function purchaseReturns(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseReturn::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\Customer::class, 'default_currency_id');
    }

    public function salesInvoices(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesInvoice::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\Order::class);
    }

    public function salesReturns(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesReturn::class);
    }

    public function carts(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\Cart::class);
    }

    public function chartOfAccounts(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\ChartOfAccount::class);
    }

    public function journalEntries(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\JournalEntry::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Payment::class);
    }

    public function expenses(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Expense::class);
    }

    public function openingBalances(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\OpeningBalance::class);
    }

    public function employees(): HasMany
    {
        return $this->hasMany(\App\Domains\HR\Models\Employee::class);
    }
}
