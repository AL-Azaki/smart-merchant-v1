<?php

namespace App\Domains\Inventory\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\Warehouse;

class WarehousePolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Warehouse $warehouse): bool
    {
        return $user->business_id === $warehouse->business_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, Warehouse $warehouse): bool
    {
        return $user->business_id === $warehouse->business_id;
    }

    public function delete(User $user, Warehouse $warehouse): bool
    {
        return $user->business_id === $warehouse->business_id;
    }

    public function restore(User $user, Warehouse $warehouse): bool
    {
        return $user->business_id === $warehouse->business_id;
    }

    public function forceDelete(User $user, Warehouse $warehouse): bool
    {
        return false;
    }
}
