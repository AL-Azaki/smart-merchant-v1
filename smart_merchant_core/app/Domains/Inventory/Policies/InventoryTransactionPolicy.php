<?php

namespace App\Domains\Inventory\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Inventory\Models\InventoryTransaction;

class InventoryTransactionPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, InventoryTransaction $transaction): bool
    {
        return $user->business_id === $transaction->business_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, InventoryTransaction $transaction): bool
    {
        return $user->business_id === $transaction->business_id && $transaction->status === 'Draft';
    }

    public function delete(User $user, InventoryTransaction $transaction): bool
    {
        return $user->business_id === $transaction->business_id && $transaction->status === 'Draft';
    }

    public function post(User $user, InventoryTransaction $transaction): bool
    {
        return $user->business_id === $transaction->business_id && $transaction->status === 'Draft';
    }

    public function reverse(User $user, InventoryTransaction $transaction): bool
    {
        return $user->business_id === $transaction->business_id && $transaction->status === 'Posted';
    }
}
