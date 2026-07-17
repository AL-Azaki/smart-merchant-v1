<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Core\Models\Account;
use Illuminate\Auth\Access\HandlesAuthorization;

class AccountPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Account $account): bool { return true; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Account $account): bool { return true; }
    public function suspend(User $user, Account $account): bool { return true; }
    public function activate(User $user, Account $account): bool { return true; }
    public function close(User $user, Account $account): bool { return true; }
}
