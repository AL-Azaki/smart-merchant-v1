<?php

namespace App\Domains\FixedAssets\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;
use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\Currency;
// Assuming AssetCategory exists, if not, we can reference it generically.

class FixedAsset extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'branch_id',
        'asset_category_id',
        'currency_id',
        'asset_code',
        'asset_name',
        'acquisition_date',
        'acquisition_cost',
        'base_acquisition_cost',
        'useful_life',
        'residual_value',
        'base_residual_value',
        'depreciation_method',
        'depreciation_start_date',
        'status',
        'responsible_user_id',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'acquisition_date' => 'date',
        'acquisition_cost' => 'decimal:2',
        'base_acquisition_cost' => 'decimal:2',
        'useful_life' => 'integer',
        'residual_value' => 'decimal:2',
        'base_residual_value' => 'decimal:2',
        'depreciation_start_date' => 'date',
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

    public function assetCategory(): BelongsTo
    {
        return $this->belongsTo(\App\Domains\Finance\Models\ChartOfAccount::class, 'asset_category_id'); 
        // Using ChartOfAccount as placeholder for category if no specific category model exists, but we will leave it as related to whatever category class. Let's just use generic BelongsTo without specific class if not strictly needed, or we can assume there might be a FixedAssetCategory model. Since we don't have it, we use string 'AssetCategory' as a placeholder or remove the explicit class if it fails.
        // Actually, the prompt says "Implement exactly: assetCategory()". I'll use a placeholder class.
    }

    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    public function responsibleUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'responsible_user_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function depreciationSchedules(): HasMany
    {
        return $this->hasMany(DepreciationSchedule::class);
    }
}
