<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\ChartOfAccount;

class ChartOfAccountPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_chart_of_accounts');
    }

    public function view(User $user, ChartOfAccount $account): bool
    {
        return $user->hasPermissionTo('view_chart_of_accounts') && $user->business_id === $account->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_chart_of_accounts');
    }

    public function update(User $user, ChartOfAccount $account): bool
    {
        return $user->hasPermissionTo('update_chart_of_accounts') && $user->business_id === $account->business_id;
    }

    public function delete(User $user, ChartOfAccount $account): bool
    {
        return $user->hasPermissionTo('delete_chart_of_accounts') && $user->business_id === $account->business_id;
    }
}
