<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\BankAccount;
use Illuminate\Auth\Access\HandlesAuthorization;

class BankAccountPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, BankAccount $bankAccount)
    {
        return true;
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, BankAccount $bankAccount)
    {
        return true;
    }

    public function freeze(User $user, BankAccount $bankAccount)
    {
        return true;
    }

    public function close(User $user, BankAccount $bankAccount)
    {
        return true;
    }

    public function createTransaction(User $user, BankAccount $bankAccount)
    {
        return true;
    }
}
