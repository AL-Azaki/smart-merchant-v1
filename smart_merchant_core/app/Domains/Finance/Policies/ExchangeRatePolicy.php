<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\ExchangeRate;

class ExchangeRatePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_exchange_rates');
    }

    public function view(User $user, ExchangeRate $exchangeRate): bool
    {
        return $user->hasPermissionTo('view_exchange_rates') && $user->business_id === $exchangeRate->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_exchange_rates');
    }

    public function update(User $user, ExchangeRate $exchangeRate): bool
    {
        return $user->hasPermissionTo('update_exchange_rates') && $user->business_id === $exchangeRate->business_id;
    }

    public function delete(User $user, ExchangeRate $exchangeRate): bool
    {
        return $user->hasPermissionTo('delete_exchange_rates') && $user->business_id === $exchangeRate->business_id;
    }
}
