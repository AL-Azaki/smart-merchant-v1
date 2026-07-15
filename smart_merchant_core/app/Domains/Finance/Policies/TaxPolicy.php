<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\Tax;

class TaxPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_taxes');
    }

    public function view(User $user, Tax $tax): bool
    {
        return $user->hasPermissionTo('view_taxes') && $user->business_id === $tax->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_taxes');
    }

    public function update(User $user, Tax $tax): bool
    {
        return $user->hasPermissionTo('update_taxes') && $user->business_id === $tax->business_id;
    }

    public function delete(User $user, Tax $tax): bool
    {
        return $user->hasPermissionTo('delete_taxes') && $user->business_id === $tax->business_id;
    }
}
