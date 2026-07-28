<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['business_id', 'branch_id', 'channel_id', 'customer_id', 'order_number', 'order_date', 'currency_id', 'exchange_rate', 'sub_total', 'discount_total', 'tax_total', 'grand_total', 'base_sub_total', 'base_discount_total', 'base_tax_total', 'base_grand_total', 'payment_status', 'status', 'notes', 'created_by', 'revision'];

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
