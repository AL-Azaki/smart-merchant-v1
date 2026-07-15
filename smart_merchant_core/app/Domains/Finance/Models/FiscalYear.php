<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;

class FiscalYear extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'fiscal_year_code',
        'fiscal_year_name',
        'description',
        'start_date',
        'end_date',
        'status',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function periods(): HasMany
    {
        return $this->hasMany(FiscalPeriod::class);
    }

    public function journalEntries(): HasMany
    {
        return $this->hasMany(JournalEntry::class);
    }

    public function openingBalances(): HasMany
    {
        return $this->hasMany(OpeningBalance::class);
    }
}
