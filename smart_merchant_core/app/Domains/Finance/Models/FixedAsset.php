<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;

class FixedAsset extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'branch_id',
        'asset_name',
        'asset_code',
        'purchase_date',
        'purchase_price',
        'salvage_value',
        'useful_life_years',
        'depreciation_method',
        'asset_account_id',
        'depreciation_account_id',
        'is_active',
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'purchase_price' => 'decimal:2',
        'salvage_value' => 'decimal:2',
        'useful_life_years' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    public function assetAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class, 'asset_account_id');
    }

    public function depreciationAccount(): BelongsTo
    {
        return $this->belongsTo(ChartOfAccount::class, 'depreciation_account_id');
    }
}
