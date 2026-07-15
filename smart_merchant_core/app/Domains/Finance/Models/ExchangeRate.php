<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Currency;

class ExchangeRate extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'source_currency_id',
        'target_currency_id',
        'effective_date',
        'rate',
    ];

    protected $casts = [
        'effective_date' => 'date',
        'rate' => 'decimal:8',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function sourceCurrency(): BelongsTo
    {
        return $this->belongsTo(Currency::class, 'source_currency_id');
    }

    public function targetCurrency(): BelongsTo
    {
        return $this->belongsTo(Currency::class, 'target_currency_id');
    }
}
