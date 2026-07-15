<?php

namespace App\Domains\Core\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Business extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'account_id',
        'business_name',
        'business_type',
        'primary_phone',
        'primary_email',
        'logo_path',
        'status',
    ];

    /**
     * Relationships
     */
    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class);
    }

    public function branches(): HasMany
    {
        return $this->hasMany(Branch::class);
    }

    public function categories(): HasMany
    {
        return $this->hasMany(\App\Domains\Catalog\Models\Category::class);
    }

    public function brands(): HasMany
    {
        return $this->hasMany(\App\Domains\Catalog\Models\Brand::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(\App\Domains\Catalog\Models\Product::class);
    }

    public function warehouses(): HasMany
    {
        return $this->hasMany(\App\Domains\Inventory\Models\Warehouse::class);
    }

    public function inventoryTransfers(): HasMany
    {
        return $this->hasMany(\App\Domains\Inventory\Models\InventoryTransfer::class);
    }

    public function suppliers(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\Supplier::class);
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
        return $this->hasMany(\App\Domains\Sales\Models\Customer::class);
    }

    public function channels(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\Channel::class);
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

    public function fiscalYears(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\FiscalYear::class);
    }

    public function fiscalPeriods(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\FiscalPeriod::class);
    }

    public function chartOfAccounts(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\ChartOfAccount::class);
    }

    public function paymentTerms(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\PaymentTerm::class);
    }

    public function paymentMethods(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\PaymentMethod::class);
    }

    public function journalEntries(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\JournalEntry::class);
    }

    public function journalEntryLines(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\JournalEntryLine::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Payment::class);
    }

    public function expenseCategories(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\ExpenseCategory::class);
    }

    public function expenses(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Expense::class);
    }

    public function openingBalances(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\OpeningBalance::class);
    }

    public function fixedAssets(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\FixedAsset::class);
    }

    public function bankReconciliations(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\BankReconciliation::class);
    }

    public function bankReconciliationLines(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\BankReconciliationLine::class);
    }

    public function taxes(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Tax::class);
    }

    public function departments(): HasMany
    {
        return $this->hasMany(\App\Domains\HR\Models\Department::class);
    }

    public function employees(): HasMany
    {
        return $this->hasMany(\App\Domains\HR\Models\Employee::class);
    }

    public function attendanceRecords(): HasMany
    {
        return $this->hasMany(\App\Domains\HR\Models\AttendanceRecord::class);
    }

    public function payrollSlips(): HasMany
    {
        return $this->hasMany(\App\Domains\HR\Models\PayrollSlip::class);
    }

    public function systemSettings(): HasMany
    {
        return $this->hasMany(\App\Domains\Extended\Models\SystemSetting::class);
    }

    public function printSettings(): HasMany
    {
        return $this->hasMany(\App\Domains\Extended\Models\PrintSetting::class);
    }
}
