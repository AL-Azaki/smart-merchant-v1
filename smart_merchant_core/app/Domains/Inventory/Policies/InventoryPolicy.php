<?php

namespace App\Domains\Inventory\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\Inventory;

class InventoryPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Inventory $inventory): bool
    {
        return $user->business_id === $inventory->business_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, Inventory $inventory): bool
    {
        return $user->business_id === $inventory->business_id;
    }

    public function delete(User $user, Inventory $inventory): bool
    {
        return $user->business_id === $inventory->business_id;
    }

    public function restore(User $user, Inventory $inventory): bool
    {
        return $user->business_id === $inventory->business_id;
    }

    public function forceDelete(User $user, Inventory $inventory): bool
    {
        return false;
    }
}
