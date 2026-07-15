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
        'setting_key',
        'setting_value',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        // Note: setting_value is not cast to 'array' globally because it can hold
        // simple strings, integers, or JSON depending on the setting_key.
        // It is recommended to handle the parsing dynamically or via an Accessor.
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
