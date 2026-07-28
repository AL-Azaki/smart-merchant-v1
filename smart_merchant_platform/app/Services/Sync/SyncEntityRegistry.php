<?php

namespace App\Services\Sync;

class SyncEntityRegistry
{
    protected array $pushAllowed = [
        'categories',
        'brands',
        'units',
        'products',
        'product_units',
        'product_images',
        'inventory_projections',
    ];

    protected array $pullAllowed = [
        'orders',
    ];

    public function canPush(string $entity): bool
    {
        return in_array($entity, $this->pushAllowed);
    }

    public function canPull(string $entity): bool
    {
        return in_array($entity, $this->pullAllowed);
    }
}
