<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Core\Models\SubscriptionPayment;
use App\Domains\Core\Models\Subscription;
use Illuminate\Auth\Access\HandlesAuthorization;

class SubscriptionPaymentPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user, Subscription $subscription): bool { return true; }
    public function view(User $user, SubscriptionPayment $payment): bool { return true; }
    public function create(User $user, Subscription $subscription): bool { return true; }
    public function updateStatus(User $user, SubscriptionPayment $payment): bool { return true; }
}
