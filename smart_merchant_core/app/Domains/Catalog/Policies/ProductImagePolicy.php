<?php

namespace App\Domains\Catalog\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Catalog\Models\productImageImage;
use Illuminate\Auth\Access\HandlesAuthorization;

class productImageImagePolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, productImageImage $productImageImage): bool { return $user->business_id === $productImageImage->business_id; }
    public function create(User $user): bool { return true; }
    public function update(User $user, productImageImage $productImageImage): bool { return $user->business_id === $productImageImage->business_id; }
    public function delete(User $user, productImageImage $productImageImage): bool { return $user->business_id === $productImageImage->business_id; }
    public function activate(User $user, productImageImage $productImageImage): bool { return $user->business_id === $productImageImage->business_id; }
    public function deactivate(User $user, productImageImage $productImageImage): bool { return $user->business_id === $productImageImage->business_id; }
}





