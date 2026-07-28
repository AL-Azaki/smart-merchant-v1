<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubscriptionPayment extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['subscription_id', 'amount', 'currency_id', 'payment_date', 'payment_method', 'transaction_id', 'status'];

    public function subscription()
    {
        return $this->belongsTo(Subscription::class);
    }

    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }
}
