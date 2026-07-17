<?php

namespace App\Domains\Catalog\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Catalog\Models\Unit;
use Illuminate\Auth\Access\HandlesAuthorization;

class UnitPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Unit $unit): bool { return $user->business_id === $unit->business_id; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Unit $unit): bool { return $user->business_id === $unit->business_id; }
    public function delete(User $user, Unit $unit): bool { return $user->business_id === $unit->business_id; }
    public function activate(User $user, Unit $unit): bool { return $user->business_id === $unit->business_id; }
    public function deactivate(User $user, Unit $unit): bool { return $user->business_id === $unit->business_id; }
}

