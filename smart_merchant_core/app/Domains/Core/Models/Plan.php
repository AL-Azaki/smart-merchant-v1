<?php

namespace App\Domains\Core\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'plan_name',
        'currency_id',
        'billing_cycle',
        'duration_months',
        'price',
        'max_businesses',
        'max_branches',
        'max_users',
        'is_active',
    ];

    protected $casts = [
        'duration_months' => 'integer',
        'price' => 'decimal:2',
        'max_businesses' => 'integer',
        'max_branches' => 'integer',
        'max_users' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }
}
