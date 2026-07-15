<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Currency;
use App\Domains\Sales\Models\Customer;
use App\Domains\Purchasing\Models\Supplier;
use App\Domains\Finance\Models\AccountType;

class ChartOfAccount extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'parent_account_id',
        'currency_id',
        'account_type_id',
        'account_code',
        'account_name',
        'description',
        'account_category',
        'normal_balance',
        'account_level',
        'allow_posting',
        'is_system',
        'is_active',
    ];

    protected $casts = [
        'account_level' => 'integer',
        'allow_posting' => 'boolean',
        'is_system' => 'boolean',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function accountType(): BelongsTo
    {
        return $this->belongsTo(AccountType::class);
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class, 'parent_account_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(ChartOfAccount::class, 'parent_account_id');
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function journalLines(): HasMany
    {
        return $this->hasMany(JournalEntryLine::class);
    }

    // Existing relations maintained
    public function paymentMethods(): HasMany
    {
        return $this->hasMany(PaymentMethod::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function expenseCategories(): HasMany
    {
        return $this->hasMany(ExpenseCategory::class);
    }

    public function openingBalances(): HasMany
    {
        return $this->hasMany(OpeningBalance::class);
    }

    public function fixedAssetsAsset(): HasMany
    {
        return $this->hasMany(FixedAsset::class, 'asset_account_id');
    }

    public function fixedAssetsDepreciation(): HasMany
    {
        return $this->hasMany(FixedAsset::class, 'depreciation_account_id');
    }

    public function bankReconciliations(): HasMany
    {
        return $this->hasMany(BankReconciliation::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class, 'receivable_account_id');
    }

    public function suppliers(): HasMany
    {
        return $this->hasMany(Supplier::class, 'payable_account_id');
    }
}
