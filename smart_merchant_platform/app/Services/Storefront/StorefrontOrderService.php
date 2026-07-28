<?php

namespace App\Services\Storefront;

use App\Models\Business;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\ProductUnit;
use App\Models\IdempotencyKey;
use App\Models\Currency;
use Illuminate\Support\Facades\DB;
use App\Http\Resources\Storefront\OrderResource;

class StorefrontOrderService
{
    public function createOrder($slug, array $data)
    {
        $business = Business::where('storefront_slug', $slug)->where('status', 'Active')->firstOrFail();

        $idempotencyKey = $data['idempotency_key'];
        
        $existing = IdempotencyKey::where('business_id', $business->id)
            ->where('idempotency_key', $idempotencyKey)
            ->first();

        if ($existing) {
            abort(409, 'Idempotency key already used or collision detected');
        }

        return DB::transaction(function () use ($business, $data, $idempotencyKey) {
            $branchId = request('branch_id') ?? $business->branches()->where('is_online_branch', true)->value('id') ?? $business->branches()->first()->id;
            
            $currencyId = Currency::first()->id; // Assume base currency for now

            $channelId = \App\Models\Channel::where('business_id', $business->id)->where('channel_name', 'ilike', '%online%')->value('id') ?? \App\Models\Channel::where('business_id', $business->id)->first()->id;

            $order = Order::create([
                'business_id' => $business->id,
                'branch_id' => $branchId,
                'channel_id' => $channelId,
                'order_number' => 'ORD-' . strtoupper(uniqid()),
                'currency_id' => $currencyId,
                'status' => 'Pending',
                'notes' => $data['notes'] ?? null,
                'revision' => 1,
            ]);

            $subTotal = 0;

            foreach ($data['items'] as $itemData) {
                $unit = ProductUnit::forBusiness($business->id)
                    ->whereHas('product', function($q) {
                        $q->where('is_active', true);
                    })
                    ->findOrFail($itemData['product_unit_id']);
                
                $quantity = $itemData['quantity'];
                
                // Advisory inventory check if requested by policy
                // Not decrementing, just validating
                $proj = \App\Models\InventoryProjection::where('product_unit_id', $unit->id)
                    ->where('branch_id', $branchId)
                    ->first();
                
                if (!$proj || $proj->quantity < $quantity) {
                    abort(422, 'Insufficient inventory for product: ' . $unit->product->product_name);
                }

                $price = $unit->selling_price;
                $total = $price * $quantity;
                $subTotal += $total;

                OrderItem::create([
                    'business_id' => $business->id,
                    'order_id' => $order->id,
                    'product_unit_id' => $unit->id,
                    'quantity' => $quantity,
                    'unit_price' => $price,
                    'line_total' => $total,
                ]);
            }

            $order->update([
                'sub_total' => $subTotal,
                'grand_total' => $subTotal,
            ]);

            IdempotencyKey::create([
                'id' => \Illuminate\Support\Str::uuid(),
                'business_id' => $business->id,
                'idempotency_key' => $idempotencyKey,
                'operation' => 'create_online_order',
                'expires_at' => now()->addDays(7),
            ]);

            return new OrderResource($order);
        });
    }
}
