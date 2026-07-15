<?php

namespace App\Domains\Core\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasUuids, SoftDeletes;

    protected $fillable = [
        'account_id',
        'default_branch_id',
        'username',
        'email',
        'password_hash',
        'full_name',
        'phone',
        'is_active',
        'last_login_at',
    ];

    protected $hidden = [
        'password_hash',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_login_at' => 'datetime',
    ];

    // Override the password field name since we used password_hash in DB
    public function getAuthPassword()
    {
        return $this->password_hash;
    }

    /**
     * Relationships
     */
    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class);
    }

    public function defaultBranch(): BelongsTo
    {
        return $this->belongsTo(Branch::class, 'default_branch_id');
    }

    public function branches(): BelongsToMany
    {
        return $this->belongsToMany(Branch::class, 'user_branches', 'user_id', 'branch_id')
                    ->withPivot('is_active', 'assigned_at');
    }

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'user_roles', 'user_id', 'role_id')
                    ->withPivot('assigned_at');
    }

    public function inventoryTransfersCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Inventory\Models\InventoryTransfer::class, 'created_by');
    }

    public function purchaseInvoicesCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseInvoice::class, 'created_by');
    }

    public function purchaseReturnsCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Purchasing\Models\PurchaseReturn::class, 'created_by');
    }

    public function salesInvoicesCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesInvoice::class, 'created_by');
    }

    public function ordersCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\Order::class, 'created_by');
    }

    public function salesReturnsCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Sales\Models\SalesReturn::class, 'created_by');
    }

    public function journalEntriesCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\JournalEntry::class, 'created_by');
    }

    public function paymentsCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Payment::class, 'created_by');
    }

    public function expensesCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\Expense::class, 'created_by');
    }

    public function bankReconciliationsCreated(): HasMany
    {
        return $this->hasMany(\App\Domains\Finance\Models\BankReconciliation::class, 'created_by');
    }

    public function employee(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(\App\Domains\HR\Models\Employee::class);
    }
}
