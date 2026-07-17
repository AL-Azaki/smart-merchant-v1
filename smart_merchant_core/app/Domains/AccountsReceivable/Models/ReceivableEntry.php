<?php

namespace App\Domains\AccountsReceivable\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Business;

class ReceivableEntry extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'customer_receivable_id',
        'entry_type',
        'direction',
        'amount',
        'foreign_currency_amount',
        'foreign_currency_code',
        'exchange_rate',
        'document_type',
        'document_id',
        'created_by',
    ];

    protected $casts = [
        'amount' => 'decimal:4',
        'foreign_currency_amount' => 'decimal:4',
        'exchange_rate' => 'decimal:6',
    ];

    /**
     * Relationships
     */
    public function customerReceivable(): BelongsTo
    {
        return $this->belongsTo(CustomerReceivable::class);
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class); // Though implicitly through parent, often useful
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function financialDocument(): MorphTo
    {
        return $this->morphTo('document');
    }
}
