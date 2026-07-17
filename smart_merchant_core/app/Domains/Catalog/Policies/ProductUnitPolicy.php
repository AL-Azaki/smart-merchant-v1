<?php

namespace App\Domains\Catalog\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Catalog\Models\productUnitUnit;
use Illuminate\Auth\Access\HandlesAuthorization;

class productUnitUnitPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, productUnitUnit $productUnitUnit): bool { return $user->business_id === $productUnitUnit->business_id; }
    public function create(User $user): bool { return true; }
    public function update(User $user, productUnitUnit $productUnitUnit): bool { return $user->business_id === $productUnitUnit->business_id; }
    public function delete(User $user, productUnitUnit $productUnitUnit): bool { return $user->business_id === $productUnitUnit->business_id; }
    public function activate(User $user, productUnitUnit $productUnitUnit): bool { return $user->business_id === $productUnitUnit->business_id; }
    public function deactivate(User $user, productUnitUnit $productUnitUnit): bool { return $user->business_id === $productUnitUnit->business_id; }
}





