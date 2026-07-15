<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Models\Core\Permission;
use Illuminate\Auth\Access\HandlesAuthorization;

class PermissionPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Permission $permission): bool
    {
        return true;
    }
}
