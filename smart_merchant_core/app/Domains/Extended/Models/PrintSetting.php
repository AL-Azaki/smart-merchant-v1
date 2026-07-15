<?php

namespace App\Domains\Extended\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Branch;

class PrintSetting extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'business_id',
        'branch_id',
        'printer_name',
        'paper_size',
        'header_text',
        'footer_text',
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
}
