<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\Payment;
use Illuminate\Auth\Access\HandlesAuthorization;

class PaymentPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_payments');
    }

    public function view(User $user, Payment $payment): bool
    {
        return $user->business_id === $payment->business_id && $user->hasPermissionTo('view_payments');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_payments');
    }

    public function update(User $user, Payment $payment): bool
    {
        return $user->business_id === $payment->business_id 
            && $payment->status === 'Draft' 
            && $user->hasPermissionTo('update_payments');
    }

    public function delete(User $user, Payment $payment): bool
    {
        return $user->business_id === $payment->business_id 
            && $payment->status === 'Draft' 
            && $user->hasPermissionTo('delete_payments');
    }

    public function post(User $user, Payment $payment): bool
    {
        return $user->business_id === $payment->business_id 
            && $payment->status === 'Draft' 
            && $user->hasPermissionTo('post_payments');
    }

    public function reverse(User $user, Payment $payment): bool
    {
        return $user->business_id === $payment->business_id 
            && $payment->status === 'Posted' 
            && $user->hasPermissionTo('reverse_payments');
    }
}
