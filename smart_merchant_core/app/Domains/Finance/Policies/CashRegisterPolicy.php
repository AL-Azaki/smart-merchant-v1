<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\CashRegister;
use Illuminate\Auth\Access\HandlesAuthorization;

class CashRegisterPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, CashRegister $cashRegister)
    {
        return true;
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, CashRegister $cashRegister)
    {
        return true;
    }

    public function open(User $user, CashRegister $cashRegister)
    {
        return true;
    }

    public function close(User $user, CashRegister $cashRegister)
    {
        return true;
    }

    public function createTransaction(User $user, CashRegister $cashRegister)
    {
        return true;
    }
}
