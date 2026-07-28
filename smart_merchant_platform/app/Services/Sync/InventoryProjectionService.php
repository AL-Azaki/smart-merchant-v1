<?php

namespace App\Services\Sync;

use App\Models\InventoryProjection;
use App\Models\ProductUnit;
use Illuminate\Support\Facades\DB;
use Exception;

class InventoryProjectionService
{
    /**
     * Upsert an inventory projection securely.
     */
    public function upsertProjection(string $businessId, string $branchId, string $productUnitId, float $quantity, int $revision): array
    {
        // Tenant Verification
        $productUnit = ProductUnit::where('id', $productUnitId)->where('business_id', $businessId)->first();
        if (!$productUnit) {
            return ['status' => 'rejected', 'reason' => 'invalid_product_unit_tenant'];
        }

        // Concurrency-safe Upsert
        // We use a transaction and a lock if needed, but DB::upsert doesn't let us conditionally ignore older revisions safely in Postgres without raw SQL.
        // So we will use a transaction, selectForUpdate on existing record if it exists.
        
        return DB::transaction(function () use ($businessId, $branchId, $productUnitId, $quantity, $revision) {
            $existing = InventoryProjection::where('business_id', $businessId)
                ->where('branch_id', $branchId)
                ->where('product_unit_id', $productUnitId)
                ->lockForUpdate()
                ->first();

            if ($existing) {
                if ($revision < $existing->revision) {
                    return ['status' => 'stale', 'server_revision' => $existing->revision];
                }
                
                if ($revision === $existing->revision) {
                    return ['status' => 'idempotent', 'server_revision' => $existing->revision];
                }

                $existing->update([
                    'quantity' => $quantity,
                    'revision' => $revision,
                ]);

                return ['status' => 'applied', 'server_revision' => $revision];
            }

            // Create if not exists
            try {
                InventoryProjection::create([
                    'business_id' => $businessId,
                    'branch_id' => $branchId,
                    'product_unit_id' => $productUnitId,
                    'quantity' => $quantity,
                    'revision' => $revision,
                ]);
                return ['status' => 'applied', 'server_revision' => $revision];
            } catch (\Illuminate\Database\QueryException $e) {
                // In case of a rare race condition where it was created just after our check
                if ($e->getCode() === '23505') { // Unique violation in Postgres
                    return $this->upsertProjection($businessId, $branchId, $productUnitId, $quantity, $revision);
                }
                throw $e;
            }
        });
    }
}
