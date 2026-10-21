<?php

namespace App\Services\Storefront;

use App\Http\Resources\Storefront\OrderResource;
use App\Models\Business;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\IdempotencyKey;
use App\Models\InventoryProjection;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\ProductUnit;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class StorefrontOrderService
{
    public function createOrder($slug, array $data)
    {
        $business = Business::where('storefront_slug', $slug)
            ->where('status', 'Active')
            ->firstOrFail();

        if (! $business->storefront_active) {
            abort(403, 'Storefront is currently closed for orders');
        }

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

            $channel = Channel::where('business_id', $business->id)
                ->where(function ($q) {
                    $q->whereRaw('LOWER(channel_name) LIKE ?', ['%online%'])
                      ->orWhere('channel_type', 'Ecommerce');
                })
                ->first()
                ?? Channel::where('business_id', $business->id)->first()
                ?? Channel::firstOrCreate(
                    [
                        'business_id' => $business->id,
                        'channel_code' => 'ONLINE-STORE-01',
                    ],
                    [
                        'id' => (string) Str::uuid(),
                        'channel_name' => 'Online Store',
                        'channel_type' => 'Ecommerce',
                        'is_active' => true,
                    ]
                );
            $channelId = $channel->id;

            $itemErrors = [];
            $validatedUnits = [];

            foreach ($data['items'] as $index => $itemData) {
                $unit = ProductUnit::eligibleForStorefront($business->id)
                    ->with('product')
                    ->find($itemData['product_unit_id']);

                if (! $unit) {
                    $itemErrors["items.{$index}.product_unit_id"] = [
                        'هذا المنتج أو خيار البيع لم يعد متاحًا.',
                    ];

                    continue;
                }

                if (isset($itemData['product_id']) && $itemData['product_id'] !== $unit->product_id) {
                    abort(422, 'Product unit does not belong to specified product');
                }

                $validatedUnits[$index] = $unit;
            }

            if (! empty($itemErrors)) {
                throw new HttpResponseException(
                    response()->json([
                        'message' => 'أحد المنتجات في السلة لم يعد متاحًا للشراء.',
                        'code' => 'PRODUCT_UNIT_UNAVAILABLE',
                        'errors' => $itemErrors,
                    ], 422)
                );
            }

            $order = Order::create([
                'business_id' => $business->id,
                'branch_id' => $branchId,
                'channel_id' => $channelId,
                'customer_id' => $data['customer_id'] ?? null,
                'customer_name' => $data['customer_name'] ?? null,
                'customer_phone' => $data['phone'] ?? $data['customer_phone'] ?? null,
                'customer_email' => $data['email'] ?? $data['customer_email'] ?? null,
                'shipping_address' => $data['address'] ?? $data['shipping_address'] ?? null,
                'shipping_city' => $data['city'] ?? $data['shipping_city'] ?? null,
                'customer_notes' => $data['notes'] ?? $data['customer_notes'] ?? null,
                'order_number' => 'ORD-'.strtoupper(uniqid()),
                'currency_id' => $currencyId,
                'status' => 'Pending',
                'source' => $data['source'] ?? 'storefront',
                'notes' => $data['internal_notes'] ?? null,
                'revision' => 1,
            ]);

            $subTotal = 0;

            foreach ($data['items'] as $index => $itemData) {
                $unit = $validatedUnits[$index];

                $quantity = $itemData['quantity'];

                // Advisory inventory check if requested by policy
                // Not decrementing, just validating
                $proj = InventoryProjection::where('product_unit_id', $unit->id)
                    ->where('branch_id', $branchId)
                    ->first();

                if (! $proj || $proj->quantity < $quantity) {
                    abort(422, 'Insufficient inventory for product: '.$unit->product->product_name);
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
                'id' => Str::uuid(),
                'business_id' => $business->id,
                'idempotency_key' => $idempotencyKey,
                'operation' => 'create_online_order',
                'expires_at' => now()->addDays(7),
            ]);

            return new OrderResource($order);
        });
    }
}
