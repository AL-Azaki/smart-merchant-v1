<?php

namespace App\Domains\Extended\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;

class SystemSetting extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'scope_business_id',
        'setting_group',
        'setting_key',
        'setting_value',
        'description',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'setting_value' => 'json',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
