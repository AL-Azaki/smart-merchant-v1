<?php

namespace App\Services\Sync;

use App\Http\Requests\Sync\AckSyncRequest;
use App\Http\Requests\Sync\PullSyncRequest;
use App\Http\Requests\Sync\PushSyncRequest;
use App\Models\Brand;
use App\Models\Business;
use App\Models\Category;
use App\Models\IdempotencyKey;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductUnit;
use App\Models\Unit;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SyncEngine
{
    public function __construct(
        protected SyncEntityRegistry $registry,
        protected InventoryProjectionService $inventoryService
    ) {}

    public function push(PushSyncRequest $request, array $context): array
    {
        $entity = $request->input('entity');

        if (! $this->registry->canPush($entity)) {
            abort(403, "Entity {$entity} cannot be pushed");
        }

        $isStorefrontSync = $request->boolean('storefront_sync') || $request->header('X-Storefront-Sync');
        if ($isStorefrontSync && in_array($entity, ['products', 'product_units', 'product_images'])) {
            $business = Business::find($context['business_id']);
            if (! $business || ! $business->storefront_active || empty($business->storefront_slug)) {
                abort(403, 'لا يمكن مزامنة المنتجات مع المتجر الإلكتروني: المتجر غير مفعّل أو لم يتم تحديد رابط المتجر.');
            }
        }

        $items = $request->input('items');
        $results = [];

        foreach ($items as $item) {
            try {
                $results[] = $this->pushItem($entity, $item, $context);
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning("Sync pushItem failed for {$entity} id {$item['id']}: " . $e->getMessage());
                $results[] = ['id' => $item['id'], 'status' => 'rejected', 'reason' => $e->getMessage()];
            }
        }

        return ['status' => 'success', 'results' => $results];
    }

    protected function pushItem(string $entity, array $item, array $context): array
    {
        if ($entity === 'inventory_projections') {
            return $this->inventoryService->upsertProjection(
                $context['business_id'],
                $item['branch_id'] ?? null,
                $item['product_unit_id'],
                $item['quantity'],
                $item['revision']
            );
        }

        // Handle others dynamically or specifically
        // In a real application, you'd map string -> class or have a factory.
        // For foundation, we stub the basic flow: check revision, upsert.
        // E.g., for Category:
        $modelClass = $this->getModelClass($entity);
        if (! $modelClass) {
            return ['id' => $item['id'], 'status' => 'rejected', 'reason' => 'unsupported_entity'];
        }

        if ($entity === 'product_units' && ! empty($item['product_id'])) {
            $parentProduct = Product::where('id', $item['product_id'])->where('business_id', $context['business_id'])->first();
            if (! $parentProduct) {
                return ['id' => $item['id'], 'status' => 'rejected', 'reason' => 'parent_product_not_found'];
            }
        }

        return DB::transaction(function () use ($modelClass, $entity, $item, $context) {
            $usesSoftDeletes = in_array(SoftDeletes::class, class_uses_recursive($modelClass));
            $query = $usesSoftDeletes
                ? $modelClass::withTrashed()->where('id', $item['id'])
                : $modelClass::where('id', $item['id']);

            if ($entity !== 'product_images') {
                $query->where('business_id', $context['business_id']);
            } else {
                $productId = $item['product_id'] ?? null;
                if ($productId) {
                    $parent = Product::where('id', $productId)->where('business_id', $context['business_id'])->first();
                    if (! $parent) {
                        return ['id' => $item['id'], 'status' => 'rejected', 'reason' => 'parent_product_tenant_mismatch'];
                    }
                }
            }

            $existing = $query->lockForUpdate()->first();

            if (! $existing && $entity !== 'product_images') {
                // If record was not found under current business, check if UUID already exists globally in DB
                // (e.g. from device re-use / switching accounts where local SQLite preserved seed records).
                $globalExisting = $usesSoftDeletes
                    ? $modelClass::withTrashed()->where('id', $item['id'])->lockForUpdate()->first()
                    : $modelClass::where('id', $item['id'])->lockForUpdate()->first();

                if ($globalExisting) {
                    $globalExisting->business_id = $context['business_id'];
                    $existing = $globalExisting;
                }
            }

            // Natural key match for standard seeded entities (Categories, Units, Brands)
            if (! $existing) {
                if ($entity === 'categories') {
                    $catName = $item['category_name'] ?? $item['name'] ?? null;
                    if ($catName) {
                        $matched = Category::where('business_id', $context['business_id'])
                            ->where('category_name', $catName)
                            ->lockForUpdate()
                            ->first();
                        if ($matched) {
                            DB::statement('UPDATE categories SET id = ? WHERE id = ?', [$item['id'], $matched->id]);
                            $existing = Category::find($item['id']);
                        }
                    }
                } elseif ($entity === 'units') {
                    $unitName = $item['unit_name'] ?? $item['name'] ?? null;
                    if ($unitName) {
                        $matched = Unit::where('business_id', $context['business_id'])
                            ->where('unit_name', $unitName)
                            ->lockForUpdate()
                            ->first();
                        if ($matched) {
                            DB::statement('UPDATE units SET id = ? WHERE id = ?', [$item['id'], $matched->id]);
                            $existing = Unit::find($item['id']);
                        }
                    }
                } elseif ($entity === 'brands') {
                    $brandName = $item['brand_name'] ?? $item['name'] ?? null;
                    if ($brandName) {
                        $matched = Brand::where('business_id', $context['business_id'])
                            ->where('brand_name', $brandName)
                            ->lockForUpdate()
                            ->first();
                        if ($matched) {
                            DB::statement('UPDATE brands SET id = ? WHERE id = ?', [$item['id'], $matched->id]);
                            $existing = Brand::find($item['id']);
                        }
                    }
                }
            }

            if ($existing) {
                if ($existing->isDirty('business_id')) {
                    $existing->save();
                }

                if ($item['revision'] < $existing->revision && ! $existing->wasChanged('business_id')) {
                    return ['id' => $item['id'], 'status' => 'stale', 'server_revision' => $existing->revision];
                }
                if ($item['revision'] === $existing->revision && ! $existing->wasChanged('business_id')) {
                    return ['id' => $item['id'], 'status' => 'idempotent', 'server_revision' => $existing->revision];
                }

                $updateData = $this->prepareEntityAttributes($entity, $item, $context);
                if ($entity !== 'product_images') {
                    $updateData['business_id'] = $context['business_id'];
                }

                if (! empty($item['deleted_at'])) {
                    $updateData['deleted_at'] = $item['deleted_at'];
                    $existing->update($updateData);
                } else {
                    if ($usesSoftDeletes && $existing->trashed()) {
                        $existing->restore();
                    }
                    $updateData['deleted_at'] = null;
                    $existing->update($updateData);
                }

                return ['id' => $item['id'], 'status' => 'applied', 'server_revision' => $item['revision']];
            }

            // create logic...
            $createData = $this->prepareEntityAttributes($entity, $item, $context);
            if ($entity !== 'product_images') {
                $createData['business_id'] = $context['business_id'];
            }
            if (! empty($item['deleted_at'])) {
                $createData['deleted_at'] = $item['deleted_at'];
            }

            $instance = new $modelClass;
            $instance->id = $item['id'];
            $instance->fill($createData);
            $instance->save();

            return ['id' => $item['id'], 'status' => 'applied', 'server_revision' => $item['revision']];
        });
    }

    protected function prepareEntityAttributes(string $entity, array $item, array $context): array
    {
        $data = ['revision' => $item['revision'] ?? 1];

        switch ($entity) {
            case 'categories':
                if (isset($item['category_name']) || isset($item['name'])) {
                    $data['category_name'] = $item['category_name'] ?? $item['name'];
                }
                if (array_key_exists('category_code', $item)) {
                    $data['category_code'] = $item['category_code'];
                }
                if (array_key_exists('parent_id', $item)) {
                    $data['parent_id'] = $item['parent_id'];
                }
                if (array_key_exists('description', $item)) {
                    $data['description'] = $item['description'];
                }
                if (array_key_exists('image_path', $item)) {
                    $data['image_path'] = $item['image_path'];
                }
                if (array_key_exists('sort_order', $item)) {
                    $data['sort_order'] = $item['sort_order'];
                }
                if (array_key_exists('is_active', $item)) {
                    $data['is_active'] = $item['is_active'];
                }
                if (array_key_exists('deleted_at', $item)) {
                    $data['deleted_at'] = $item['deleted_at'];
                }
                break;

            case 'brands':
                if (isset($item['brand_name']) || isset($item['name'])) {
                    $data['brand_name'] = $item['brand_name'] ?? $item['name'];
                }
                if (array_key_exists('description', $item)) {
                    $data['description'] = $item['description'];
                }
                if (array_key_exists('logo_path', $item)) {
                    $data['logo_path'] = $item['logo_path'];
                }
                if (array_key_exists('is_active', $item)) {
                    $data['is_active'] = $item['is_active'];
                }
                if (array_key_exists('deleted_at', $item)) {
                    $data['deleted_at'] = $item['deleted_at'];
                }
                break;

            case 'units':
                if (isset($item['unit_name']) || isset($item['name'])) {
                    $data['unit_name'] = $item['unit_name'] ?? $item['name'];
                }
                if (isset($item['unit_symbol']) || isset($item['unit_code']) || isset($item['short_name'])) {
                    $data['unit_symbol'] = $item['unit_symbol'] ?? $item['unit_code'] ?? $item['short_name'];
                }
                if (array_key_exists('unit_description', $item) || array_key_exists('description', $item)) {
                    $data['unit_description'] = $item['unit_description'] ?? $item['description'] ?? null;
                }
                if (array_key_exists('is_active', $item)) {
                    $data['is_active'] = $item['is_active'];
                }
                if (array_key_exists('deleted_at', $item)) {
                    $data['deleted_at'] = $item['deleted_at'];
                }
                break;

            case 'products':
                if (isset($item['product_name']) || isset($item['name'])) {
                    $data['product_name'] = $item['product_name'] ?? $item['name'];
                }
                if (array_key_exists('product_code', $item)) {
                    $data['product_code'] = $item['product_code'];
                }
                if (array_key_exists('product_type', $item)) {
                    $data['product_type'] = $item['product_type'];
                }
                if (array_key_exists('category_id', $item)) {
                    $catId = $item['category_id'];
                    if ($catId && ! Category::where('id', $catId)->exists()) {
                        $fallbackCat = Category::where('business_id', $context['business_id'])->first();
                        $data['category_id'] = $fallbackCat ? $fallbackCat->id : null;
                    } else {
                        $data['category_id'] = $catId;
                    }
                }
                if (array_key_exists('brand_id', $item)) {
                    $brandId = $item['brand_id'];
                    if ($brandId && ! Brand::where('id', $brandId)->exists()) {
                        $data['brand_id'] = null;
                    } else {
                        $data['brand_id'] = $brandId;
                    }
                }
                if (array_key_exists('tax_id', $item)) {
                    $data['tax_id'] = $item['tax_id'];
                }
                if (array_key_exists('description', $item)) {
                    $data['description'] = $item['description'];
                }
                if (array_key_exists('is_active', $item)) {
                    $data['is_active'] = $item['is_active'];
                }
                if (array_key_exists('show_in_store', $item)) {
                    $data['show_in_store'] = (bool) $item['show_in_store'];
                }
                if (array_key_exists('deleted_at', $item)) {
                    $data['deleted_at'] = $item['deleted_at'];
                }
                break;

            case 'product_units':
                if (array_key_exists('product_id', $item)) {
                    $data['product_id'] = $item['product_id'];
                }
                if (array_key_exists('unit_id', $item)) {
                    $unitId = $item['unit_id'];
                    if ($unitId && ! Unit::where('id', $unitId)->exists()) {
                        $fallbackUnit = Unit::where('business_id', $context['business_id'])->first();
                        $data['unit_id'] = $fallbackUnit ? $fallbackUnit->id : $unitId;
                    } else {
                        $data['unit_id'] = $unitId;
                    }
                }
                if (array_key_exists('barcode', $item)) {
                    $data['barcode'] = $item['barcode'];
                }
                if (array_key_exists('sku', $item)) {
                    $data['sku'] = $item['sku'];
                }
                if (array_key_exists('conversion_factor', $item)) {
                    $data['conversion_factor'] = $item['conversion_factor'];
                }
                if (isset($item['selling_price']) || isset($item['price'])) {
                    $data['selling_price'] = $item['selling_price'] ?? $item['price'];
                }
                if (isset($item['purchase_price']) || isset($item['cost_price'])) {
                    $data['purchase_price'] = $item['purchase_price'] ?? $item['cost_price'];
                }
                if (array_key_exists('minimum_price', $item)) {
                    $data['minimum_price'] = $item['minimum_price'];
                }
                if (array_key_exists('is_base_unit', $item)) {
                    $data['is_base_unit'] = $item['is_base_unit'];
                }
                if (array_key_exists('is_active', $item)) {
                    $data['is_active'] = $item['is_active'];
                }
                if (array_key_exists('deleted_at', $item)) {
                    $data['deleted_at'] = $item['deleted_at'];
                }
                break;

            case 'product_images':
                if (array_key_exists('product_id', $item)) {
                    $data['product_id'] = $item['product_id'];
                }
                if (isset($item['image_path']) || isset($item['image_url'])) {
                    $data['image_path'] = $item['image_path'] ?? $item['image_url'];
                }
                if (array_key_exists('is_primary', $item)) {
                    $data['is_primary'] = (bool) $item['is_primary'];
                }
                break;

            default:
                foreach ($item as $k => $v) {
                    if (! in_array($k, ['id', 'business_id'])) {
                        $data[$k] = $v;
                    }
                }
                break;
        }

        return $data;
    }

    public function pull(PullSyncRequest $request, array $context): array
    {
        $entity = $request->input('entity');

        if (! $this->registry->canPull($entity)) {
            abort(403, "Entity {$entity} cannot be pulled");
        }

        $cursor = (int) ($request->input('cursor') ?? 0);
        $limit = (int) ($request->input('limit') ?? 50);

        if ($entity === 'orders') {
            $items = Order::with('items')
                ->where('business_id', $context['business_id'])
                ->where('revision', '>', $cursor)
                ->orderBy('revision', 'asc')
                ->limit($limit)
                ->get();

            $nextCursor = $items->last()?->revision ?? $cursor;

            return [
                'status' => 'success',
                'items' => $items,
                'next_cursor' => $nextCursor,
            ];
        }

        return ['status' => 'success', 'items' => []];
    }

    public function ack(AckSyncRequest $request, array $context): array
    {
        $entity = $request->input('entity');
        $idemKey = $request->input('idempotency_key');

        // Idempotency check
        $idempotency = IdempotencyKey::where('idempotency_key', $idemKey)
            ->where('business_id', $context['business_id'])
            ->first();

        if ($idempotency) {
            // Idempotent retry, just return success
            return ['status' => 'success', 'message' => 'Idempotent replay'];
        }

        $items = $request->input('items');
        $results = [];

        foreach ($items as $item) {
            if ($entity === 'orders') {
                $order = Order::where('id', $item['id'])->where('business_id', $context['business_id'])->first();
                if ($order && $order->revision <= $item['revision']) {
                    $order->update(['status' => 'Acknowledged']); // simplified
                    $results[] = ['id' => $item['id'], 'status' => 'acked'];
                } else {
                    $results[] = ['id' => $item['id'], 'status' => 'not_found_or_stale'];
                }
            }
        }

        $response = ['status' => 'success', 'results' => $results];

        // Store Idempotency
        IdempotencyKey::create([
            'business_id' => $context['business_id'],
            'idempotency_key' => $idemKey,
            'operation' => 'ack',
            'expires_at' => now()->addDays(7),
        ]);

        return $response;
    }

    public function updateOrderStatus(string $orderId, array $data, array $context): array
    {
        $businessId = $context['business_id'];
        $idempotencyKey = $data['idempotency_key'];
        $targetStatus = $data['status'];

        $order = Order::where('business_id', $businessId)->find($orderId);
        if (! $order) {
            abort(404, 'Order not found in this business context');
        }

        // 1. Idempotency Check
        $existingIdempotency = IdempotencyKey::where('business_id', $businessId)
            ->where('idempotency_key', $idempotencyKey)
            ->first();

        if ($existingIdempotency) {
            $expectedOpPrefix = "update_order_status:{$orderId}:{$targetStatus}";
            if (str_starts_with($existingIdempotency->operation, $expectedOpPrefix)) {
                return [
                    'status' => 'success',
                    'message' => 'Idempotent replay',
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'order_status' => $order->status,
                    'pos_invoice_reference' => $order->pos_invoice_reference,
                    'completed_at' => $order->completed_at?->toIso8601String(),
                ];
            }

            abort(409, 'Idempotency key collision: key already used for a different operation or status');
        }

        // 2. Safe No-Op: If already in requested status (under a new key)
        if ($order->status === $targetStatus) {
            return [
                'status' => 'success',
                'message' => 'Order is already in requested status',
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'order_status' => $order->status,
                'pos_invoice_reference' => $order->pos_invoice_reference,
                'completed_at' => $order->completed_at?->toIso8601String(),
            ];
        }

        // 3. State Machine Validation
        // Allowed transitions:
        // Acknowledged -> Confirmed
        // Acknowledged -> Cancelled
        // Confirmed -> Delivered
        $allowedTransitions = [
            'Acknowledged' => ['Confirmed', 'Cancelled'],
            'Confirmed' => ['Delivered'],
        ];

        $currentStatus = $order->status;
        $allowedNext = $allowedTransitions[$currentStatus] ?? [];

        if (! in_array($targetStatus, $allowedNext, true)) {
            abort(422, "Invalid order status transition from {$currentStatus} to {$targetStatus}");
        }

        // 4. Atomic Execution within DB transaction
        return DB::transaction(function () use ($order, $data, $businessId, $idempotencyKey, $targetStatus, $orderId) {
            $updateData = ['status' => $targetStatus];

            if ($targetStatus === 'Delivered') {
                $updateData['completed_at'] = $data['completed_at'] ?? now();
                $invoiceRef = $data['invoice_number'] ?? $data['invoice_id'] ?? null;
                if ($invoiceRef) {
                    $updateData['pos_invoice_reference'] = $invoiceRef;
                }
            }

            if (isset($data['revision']) && $data['revision'] > $order->revision) {
                $updateData['revision'] = $data['revision'];
            } else {
                $updateData['revision'] = $order->revision + 1;
            }

            $order->update($updateData);

            // Record Idempotency Key
            IdempotencyKey::create([
                'id' => (string) Str::uuid(),
                'business_id' => $businessId,
                'idempotency_key' => $idempotencyKey,
                'operation' => "update_order_status:{$orderId}:{$targetStatus}",
                'expires_at' => now()->addDays(7),
            ]);

            return [
                'status' => 'success',
                'message' => "Order status updated to {$targetStatus}",
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'order_status' => $order->fresh()->status,
                'pos_invoice_reference' => $order->fresh()->pos_invoice_reference,
                'completed_at' => $order->fresh()->completed_at?->toIso8601String(),
            ];
        });
    }

    protected function getModelClass(string $entity): ?string
    {
        $map = [
            'categories' => Category::class,
            'brands' => Brand::class,
            'units' => Unit::class,
            'products' => Product::class,
            'product_units' => ProductUnit::class,
            'product_images' => ProductImage::class,
        ];

        return $map[$entity] ?? null;
    }
}
