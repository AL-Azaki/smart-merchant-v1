<?php

namespace App\Domains\Sales\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Domains\Core\Models\Business;
use App\Domains\Catalog\Models\ProductUnit;

class Channel extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false; // The migration only has uuid, strings and boolean, no timestamps in DB

    protected $fillable = [
        'business_id',
        'channel_name',
        'channel_code',
        'channel_type',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Relationships
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function carts(): HasMany
    {
        return $this->hasMany(Cart::class);
    }

    public function productUnits(): BelongsToMany
    {
        return $this->belongsToMany(ProductUnit::class, 'product_channels', 'channel_id', 'product_unit_id')
                    ->withPivot('sale_price', 'is_enabled', 'display_order');
    }
}
