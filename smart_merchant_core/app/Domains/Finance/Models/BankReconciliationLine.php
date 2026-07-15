<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;

class BankReconciliationLine extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // No timestamps in DB for this table

    protected $fillable = [
        'business_id',
        'bank_reconciliation_id',
        'journal_entry_line_id',
        'is_cleared',
        'clearance_date',
    ];

    protected $casts = [
        'is_cleared' => 'boolean',
        'clearance_date' => 'date',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function bankReconciliation(): BelongsTo
    {
        return $this->belongsTo(BankReconciliation::class);
    }

    public function journalEntryLine(): BelongsTo
    {
        return $this->belongsTo(JournalEntryLine::class);
    }
}
