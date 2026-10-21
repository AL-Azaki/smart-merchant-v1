<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id',
        'branch_id',
        'channel_id',
        'customer_id',
        'customer_name',
        'customer_phone',
        'customer_email',
        'shipping_address',
        'shipping_city',
        'customer_notes',
        'order_number',
        'order_date',
        'currency_id',
        'exchange_rate',
        'sub_total',
        'discount_total',
        'tax_total',
        'grand_total',
        'base_sub_total',
        'base_discount_total',
        'base_tax_total',
        'base_grand_total',
        'payment_status',
        'status',
        'source',
        'notes',
        'pos_invoice_reference',
        'completed_at',
        'created_by',
        'revision',
    ];

    protected $casts = [
        'completed_at' => 'datetime',
        'order_date' => 'date',
        'sub_total' => 'decimal:4',
        'grand_total' => 'decimal:4',
    ];

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function channel()
    {
        return $this->belongsTo(Channel::class);
    }

    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }
}
