<?php

namespace App\Domains\Catalog\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Catalog\Models\Category;
use Illuminate\Auth\Access\HandlesAuthorization;

class CategoryPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Category $category): bool { return $user->business_id === $category->business_id; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Category $category): bool { return $user->business_id === $category->business_id; }
    public function delete(User $user, Category $category): bool { return $user->business_id === $category->business_id; }
    public function activate(User $user, Category $category): bool { return $user->business_id === $category->business_id; }
    public function deactivate(User $user, Category $category): bool { return $user->business_id === $category->business_id; }
}



