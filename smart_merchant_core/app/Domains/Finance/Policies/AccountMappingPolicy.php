<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\AccountMapping;
use Illuminate\Auth\Access\HandlesAuthorization;

class AccountMappingPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return $user->hasPermissionTo('finance.account_mapping.view');
    }

    public function create(User $user)
    {
        return $user->hasPermissionTo('finance.account_mapping.create');
    }

    public function view(User $user, AccountMapping $accountMapping)
    {
        return $user->hasPermissionTo('finance.account_mapping.view');
    }

    public function update(User $user, AccountMapping $accountMapping)
    {
        return $user->hasPermissionTo('finance.account_mapping.update');
    }

    public function delete(User $user, AccountMapping $accountMapping)
    {
        return $user->hasPermissionTo('finance.account_mapping.delete');
    }
}
