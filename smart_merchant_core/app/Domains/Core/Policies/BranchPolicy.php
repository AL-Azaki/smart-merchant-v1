<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Branch;
use Illuminate\Auth\Access\HandlesAuthorization;

class BranchPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool
    {
        return true; 
    }

    public function view(User $user, Branch $branch): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        // Authorization to create a branch within a business context
        return true;
    }

    public function update(User $user, Branch $branch): bool
    {
        return true;
    }

    public function delete(User $user, Branch $branch): bool
    {
        return true;
    }
}
