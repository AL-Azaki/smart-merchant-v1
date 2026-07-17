<?php

namespace App\Domains\Catalog\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Catalog\Models\BranchbranchProductPricePrice;
use Illuminate\Auth\Access\HandlesAuthorization;

class BranchbranchProductPricePricePolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, BranchbranchProductPricePrice $BranchbranchProductPricePrice): bool { return $user->business_id === $BranchbranchProductPricePrice->business_id; }
    public function create(User $user): bool { return true; }
    public function update(User $user, BranchbranchProductPricePrice $BranchbranchProductPricePrice): bool { return $user->business_id === $BranchbranchProductPricePrice->business_id; }
    public function delete(User $user, BranchbranchProductPricePrice $BranchbranchProductPricePrice): bool { return $user->business_id === $BranchbranchProductPricePrice->business_id; }
    public function activate(User $user, BranchbranchProductPricePrice $BranchbranchProductPricePrice): bool { return $user->business_id === $BranchbranchProductPricePrice->business_id; }
    public function deactivate(User $user, BranchbranchProductPricePrice $BranchbranchProductPricePrice): bool { return $user->business_id === $BranchbranchProductPricePrice->business_id; }
}





