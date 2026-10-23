<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'account_id',
        'plan_id',
        'start_date',
        'end_date',
        'amount_paid',
        'total_amount',
        'installments_count',
        'installment_frequency',
        'status',
        'offline_lease_valid_until',
        'max_offline_days',
        'grace_period_days',
        'notes',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'offline_lease_valid_until' => 'datetime',
        'amount_paid' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'installments_count' => 'integer',
        'max_offline_days' => 'integer',
        'grace_period_days' => 'integer',
    ];

    public function account()
    {
        return $this->belongsTo(Account::class);
    }

    public function plan()
    {
        return $this->belongsTo(Plan::class);
    }

    public function installments()
    {
        return $this->hasMany(SubscriptionInstallment::class)->orderBy('installment_number');
    }

    public function payments()
    {
        return $this->hasMany(SubscriptionPayment::class)->orderByDesc('payment_date');
    }

    public function getRemainingAmountAttribute(): float
    {
        return max(0, (float)$this->total_amount - (float)$this->amount_paid);
    }

    public function nextDueInstallment()
    {
        return $this->installments()->where('status', '!=', 'Paid')->orderBy('installment_number')->first();
    }
}
