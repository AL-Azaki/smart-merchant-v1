<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\FiscalYear;

class FiscalYearPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_fiscal_years');
    }

    public function view(User $user, FiscalYear $fiscalYear): bool
    {
        return $user->hasPermissionTo('view_fiscal_years') && $user->business_id === $fiscalYear->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_fiscal_years');
    }

    public function update(User $user, FiscalYear $fiscalYear): bool
    {
        return $user->hasPermissionTo('update_fiscal_years') && $user->business_id === $fiscalYear->business_id;
    }

    public function delete(User $user, FiscalYear $fiscalYear): bool
    {
        return $user->hasPermissionTo('delete_fiscal_years') && $user->business_id === $fiscalYear->business_id;
    }
}
