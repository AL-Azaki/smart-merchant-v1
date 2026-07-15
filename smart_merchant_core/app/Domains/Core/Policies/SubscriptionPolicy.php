<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Models\Core\Subscription;
use App\Models\Core\Account;
use Illuminate\Auth\Access\HandlesAuthorization;

class SubscriptionPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user, Account $account): bool { return true; }
    public function view(User $user, Subscription $subscription): bool { return true; }
    public function create(User $user, Account $account): bool { return true; }
    public function updateStatus(User $user, Subscription $subscription): bool { return true; }
}
