<?php

namespace App\Domains\Finance\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;

class PaymentTerm extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'term_name',
        'days_to_due',
        'is_active',
    ];

    protected $casts = [
        'days_to_due' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
