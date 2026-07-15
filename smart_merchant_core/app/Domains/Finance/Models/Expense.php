<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;

class Expense extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'branch_id',
        'expense_category_id',
        'payment_method_id',
        'expense_number',
        'expense_date',
        'amount',
        'tax_amount',
        'total_amount',
        'currency_id',
        'exchange_rate',
        'base_total_amount',
        'description',
        'created_by',
    ];

    protected $casts = [
        'expense_date' => 'datetime',
        'amount' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'exchange_rate' => 'decimal:8',
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

    public function expenseCategory(): BelongsTo
    {
        return $this->belongsTo(ExpenseCategory::class);
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
