<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class UserPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, User $model): bool { return true; }
    public function create(User $user): bool { return true; }
    public function update(User $user, User $model): bool { return true; }
    public function suspend(User $user, User $model): bool { return true; }
    public function activate(User $user, User $model): bool { return true; }
    public function syncRoles(User $user, User $model): bool { return true; }
    public function syncBranches(User $user, User $model): bool { return true; }
}
