<?php

namespace App\Domains\AccountsPayable\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;
use App\Domains\Purchasing\Models\Supplier; // Assuming Supplier is in Purchasing domain

class SupplierPayable extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'supplier_id',
        'branch_id',
        'currency_id',
        'status',
        'current_balance',
        'due_date',
        'responsible_user_id',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'current_balance' => 'decimal:4',
        'due_date' => 'date',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class);
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function entries(): HasMany
    {
        return $this->hasMany(PayableEntry::class);
    }
}
