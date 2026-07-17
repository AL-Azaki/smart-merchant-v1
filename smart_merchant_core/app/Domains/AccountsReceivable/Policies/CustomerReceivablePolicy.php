<?php

namespace App\Domains\AccountsReceivable\Policies;

use App\Domains\Core\Models\User;
use App\Domains\AccountsReceivable\Models\CustomerReceivable;
use Illuminate\Auth\Access\HandlesAuthorization;

class CustomerReceivablePolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, CustomerReceivable $receivable)
    {
        return true;
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, CustomerReceivable $receivable)
    {
        return true;
    }

    public function recordEntry(User $user, CustomerReceivable $receivable)
    {
        return true; // Authorize based on permissions
    }
}
