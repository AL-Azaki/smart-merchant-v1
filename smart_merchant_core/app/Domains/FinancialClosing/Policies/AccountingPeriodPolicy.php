<?php

namespace App\Domains\FinancialClosing\Policies;

use App\Domains\Core\Models\User;
use App\Domains\FinancialClosing\Models\AccountingPeriod;
use Illuminate\Auth\Access\HandlesAuthorization;

class AccountingPeriodPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, AccountingPeriod $accountingPeriod)
    {
        return true;
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, AccountingPeriod $accountingPeriod)
    {
        return $accountingPeriod->status !== 'Closed';
    }

    public function close(User $user, AccountingPeriod $accountingPeriod)
    {
        return in_array($accountingPeriod->status, ['Open', 'Reopened']);
    }

    public function reopen(User $user, AccountingPeriod $accountingPeriod)
    {
        return $accountingPeriod->status === 'Closed';
    }
}
