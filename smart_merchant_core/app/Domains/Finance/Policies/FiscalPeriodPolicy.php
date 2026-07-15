<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\FiscalPeriod;

class FiscalPeriodPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_fiscal_periods');
    }

    public function view(User $user, FiscalPeriod $fiscalPeriod): bool
    {
        return $user->hasPermissionTo('view_fiscal_periods') && $user->business_id === $fiscalPeriod->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_fiscal_periods');
    }

    public function update(User $user, FiscalPeriod $fiscalPeriod): bool
    {
        return $user->hasPermissionTo('update_fiscal_periods') && $user->business_id === $fiscalPeriod->business_id;
    }

    public function delete(User $user, FiscalPeriod $fiscalPeriod): bool
    {
        return $user->hasPermissionTo('delete_fiscal_periods') && $user->business_id === $fiscalPeriod->business_id;
    }
}
