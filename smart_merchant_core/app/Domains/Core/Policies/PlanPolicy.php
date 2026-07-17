<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Plan;
use Illuminate\Auth\Access\HandlesAuthorization;

class PlanPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Plan $plan): bool { return true; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Plan $plan): bool { return true; }
    public function delete(User $user, Plan $plan): bool { return true; }
    public function activate(User $user, Plan $plan): bool { return true; }
    public function deactivate(User $user, Plan $plan): bool { return true; }
}
