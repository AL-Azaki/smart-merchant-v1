<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Currency;

class OpeningBalance extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'fiscal_year_id',
        'chart_of_account_id',
        'debit',
        'credit',
        'currency_id',
        'exchange_rate',
        'base_debit',
        'base_credit',
    ];

    protected $casts = [
        'debit' => 'decimal:2',
        'credit' => 'decimal:2',
        'exchange_rate' => 'decimal:8',
        'base_debit' => 'decimal:2',
        'base_credit' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function fiscalYear(): BelongsTo
    {
        return $this->belongsTo(FiscalYear::class);
    }

    public function chartOfAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class);
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }
}
