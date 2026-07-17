<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use App\Domains\Core\Models\Currency;

class JournalEntryLine extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // No timestamps in DB for this table

    protected $fillable = [
        'business_id',
        'journal_entry_id',
        'line_number',
        'chart_of_account_id',
        'description',
        'currency_id',
        'exchange_rate',
        'type',
        'foreign_amount',
        'base_amount',
        'document_type',
        'document_id',
    ];

    protected $casts = [
        'line_number' => 'integer',
        'exchange_rate' => 'decimal:8',
        'foreign_amount' => 'decimal:2',
        'base_amount' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function journalEntry(): BelongsTo
    {
        return $this->belongsTo(JournalEntry::class);
    }

    public function chartOfAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class);
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function financialDocument(): MorphTo
    {
        return $this->morphTo('document');
    }
}
