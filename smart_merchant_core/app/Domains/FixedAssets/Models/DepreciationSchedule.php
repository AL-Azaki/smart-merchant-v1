<?php

namespace App\Domains\FixedAssets\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\User;

class DepreciationSchedule extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'fixed_asset_id',
        'depreciation_period',
        'scheduled_posting_date',
        'depreciation_amount',
        'base_depreciation_amount',
        'accumulated_depreciation',
        'base_accumulated_depreciation',
        'remaining_book_value',
        'base_remaining_book_value',
        'status',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'depreciation_period' => 'integer',
        'scheduled_posting_date' => 'date',
        'depreciation_amount' => 'decimal:2',
        'base_depreciation_amount' => 'decimal:2',
        'accumulated_depreciation' => 'decimal:2',
        'base_accumulated_depreciation' => 'decimal:2',
        'remaining_book_value' => 'decimal:2',
        'base_remaining_book_value' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function fixedAsset(): BelongsTo
    {
        return $this->belongsTo(FixedAsset::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
