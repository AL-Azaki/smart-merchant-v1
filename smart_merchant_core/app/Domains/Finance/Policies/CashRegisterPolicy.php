<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\CashRegister;

class CashRegisterPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_cash_registers');
    }

    public function view(User $user, CashRegister $cashRegister): bool
    {
        return $user->hasPermissionTo('view_cash_registers') && $user->business_id === $cashRegister->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_cash_registers');
    }

    public function update(User $user, CashRegister $cashRegister): bool
    {
        return $user->hasPermissionTo('update_cash_registers') && $user->business_id === $cashRegister->business_id;
    }

    public function delete(User $user, CashRegister $cashRegister): bool
    {
        return $user->hasPermissionTo('delete_cash_registers') && $user->business_id === $cashRegister->business_id;
    }
}
