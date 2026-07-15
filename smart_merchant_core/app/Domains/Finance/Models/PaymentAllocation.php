<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\User;

class PaymentAllocation extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'payment_id',
        'amount',
        'document_type',
        'document_id',
        'created_by',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function document(): MorphTo
    {
        return $this->morphTo();
    }
}
