<?php

namespace App\Domains\Catalog\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Catalog\Models\Product;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProductPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Product $Product): bool { return $user->business_id === $Product->business_id; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Product $Product): bool { return $user->business_id === $Product->business_id; }
    public function delete(User $user, Product $Product): bool { return $user->business_id === $Product->business_id; }
    public function activate(User $user, Product $Product): bool { return $user->business_id === $Product->business_id; }
    public function deactivate(User $user, Product $Product): bool { return $user->business_id === $Product->business_id; }
}




