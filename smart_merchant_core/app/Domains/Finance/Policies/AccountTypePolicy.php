<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;

class AccountTypePolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_account_types');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user): bool
    {
        return $user->hasPermissionTo('view_account_types');
    }
}
