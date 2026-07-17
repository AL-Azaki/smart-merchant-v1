<?php

namespace App\Domains\AccountsPayable\Policies;

use App\Domains\Core\Models\User;
use App\Domains\AccountsPayable\Models\SupplierPayable;
use Illuminate\Auth\Access\HandlesAuthorization;

class SupplierPayablePolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, SupplierPayable $payable)
    {
        return true;
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, SupplierPayable $payable)
    {
        return true;
    }

    public function recordEntry(User $user, SupplierPayable $payable)
    {
        return true;
    }
}
