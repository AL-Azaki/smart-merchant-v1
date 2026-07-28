<?php

namespace App\Services\Sync;

use App\Http\Requests\Sync\PushSyncRequest;
use App\Http\Requests\Sync\PullSyncRequest;
use App\Http\Requests\Sync\AckSyncRequest;
use App\Models\IdempotencyKey;
use App\Models\Order;
use App\Models\Category;
use App\Models\Brand;
use App\Models\Unit;
use App\Models\Product;
use App\Models\ProductUnit;
use Illuminate\Support\Facades\DB;

class SyncEngine
{
    public function __construct(
        protected SyncEntityRegistry $registry,
        protected InventoryProjectionService $inventoryService
    ) {}

    public function push(PushSyncRequest $request, array $context): array
    {
        $entity = $request->input('entity');
        
        if (!$this->registry->canPush($entity)) {
            abort(403, "Entity {$entity} cannot be pushed");
        }

        $items = $request->input('items');
        $results = [];

        foreach ($items as $item) {
            $results[] = $this->pushItem($entity, $item, $context);
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
        if (!$modelClass) {
             return ['id' => $item['id'], 'status' => 'rejected', 'reason' => 'unsupported_entity'];
        }
        
        return DB::transaction(function () use ($modelClass, $item, $context) {
             $existing = $modelClass::where('id', $item['id'])
                ->where('business_id', $context['business_id'])
                ->lockForUpdate()
                ->first();

             if ($existing) {
                 if ($item['revision'] < $existing->revision) {
                     return ['id' => $item['id'], 'status' => 'stale', 'server_revision' => $existing->revision];
                 }
                 if ($item['revision'] === $existing->revision) {
                     return ['id' => $item['id'], 'status' => 'idempotent', 'server_revision' => $existing->revision];
                 }
                 
                 // update logic... omitting dynamic fields for brevity in foundation
                 $existing->update(['revision' => $item['revision']]);
                 return ['id' => $item['id'], 'status' => 'applied', 'server_revision' => $item['revision']];
             }

             // create logic...
             $item['business_id'] = $context['business_id'];
             try {
                 $modelClass::create($item);
                 return ['id' => $item['id'], 'status' => 'applied', 'server_revision' => $item['revision']];
             } catch (\Exception $e) {
                 return ['id' => $item['id'], 'status' => 'error', 'reason' => $e->getMessage()];
             }
        });
    }

    public function pull(PullSyncRequest $request, array $context): array
    {
        $entity = $request->input('entity');
        
        if (!$this->registry->canPull($entity)) {
            abort(403, "Entity {$entity} cannot be pulled");
        }

        $cursor = $request->input('cursor', 0);
        $limit = $request->input('limit', 50);

        if ($entity === 'orders') {
            $items = Order::where('business_id', $context['business_id'])
                ->where('revision', '>', $cursor)
                ->orderBy('revision', 'asc')
                ->limit($limit)
                ->get();
                
            $nextCursor = $items->last()?->revision ?? $cursor;

            return [
                'status' => 'success',
                'items' => $items,
                'next_cursor' => $nextCursor
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

    protected function getModelClass(string $entity): ?string
    {
        $map = [
            'categories' => Category::class,
            'brands' => Brand::class,
            'units' => Unit::class,
            'products' => Product::class,
            'product_units' => ProductUnit::class,
        ];
        return $map[$entity] ?? null;
    }
}
