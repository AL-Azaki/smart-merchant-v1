<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Role;
use Illuminate\Auth\Access\HandlesAuthorization;

class RolePolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Role $role): bool { return true; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Role $role): bool { return true; }
    public function delete(User $user, Role $role): bool { return true; }
    public function syncPermissions(User $user, Role $role): bool { return true; }
}
