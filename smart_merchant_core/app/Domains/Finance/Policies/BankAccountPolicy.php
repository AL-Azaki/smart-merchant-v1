<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\BankAccount;

class BankAccountPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_bank_accounts');
    }

    public function view(User $user, BankAccount $bankAccount): bool
    {
        return $user->hasPermissionTo('view_bank_accounts') && $user->business_id === $bankAccount->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_bank_accounts');
    }

    public function update(User $user, BankAccount $bankAccount): bool
    {
        return $user->hasPermissionTo('update_bank_accounts') && $user->business_id === $bankAccount->business_id;
    }

    public function delete(User $user, BankAccount $bankAccount): bool
    {
        return $user->hasPermissionTo('delete_bank_accounts') && $user->business_id === $bankAccount->business_id;
    }
}
