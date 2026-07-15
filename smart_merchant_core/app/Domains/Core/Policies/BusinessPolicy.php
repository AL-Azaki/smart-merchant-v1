<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Business;
use Illuminate\Auth\Access\HandlesAuthorization;

class BusinessPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool
    {
        return true; 
    }

    public function view(User $user, Business $business): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        // Business creation is typically a platform admin action or specific self-registration flow
        return true;
    }

    public function update(User $user, Business $business): bool
    {
        return true;
    }
}
