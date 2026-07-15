<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\PaymentTerm;

class PaymentTermPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view_payment_terms');
    }

    public function view(User $user, PaymentTerm $paymentTerm): bool
    {
        return $user->hasPermissionTo('view_payment_terms') && $user->business_id === $paymentTerm->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create_payment_terms');
    }

    public function update(User $user, PaymentTerm $paymentTerm): bool
    {
        return $user->hasPermissionTo('update_payment_terms') && $user->business_id === $paymentTerm->business_id;
    }

    public function delete(User $user, PaymentTerm $paymentTerm): bool
    {
        return $user->hasPermissionTo('delete_payment_terms') && $user->business_id === $paymentTerm->business_id;
    }
}
