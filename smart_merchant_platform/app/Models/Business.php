<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Business extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'account_id',
        'business_name',
        'business_type',
        'primary_phone',
        'primary_email',
        'logo_path',
        'status',
        'revision',
        'storefront_slug',
        'storefront_display_name',
        'storefront_active',
        'storefront_whatsapp',
        'storefront_phone',
        'storefront_address_text',
        'storefront_lat',
        'storefront_lng',
        'storefront_theme_settings',
        'storefront_categories',
    ];

    protected $casts = [
        'storefront_active' => 'boolean',
        'storefront_lat' => 'decimal:7',
        'storefront_lng' => 'decimal:7',
        'storefront_theme_settings' => 'array',
        'storefront_categories' => 'array',
    ];

    public function account()
    {
        return $this->belongsTo(Account::class);
    }

    public function branches()
    {
        return $this->hasMany(Branch::class);
    }

    public function users()
    {
        return $this->belongsToMany(User::class, 'user_branches');
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function devices()
    {
        return $this->hasMany(Device::class);
    }
}
