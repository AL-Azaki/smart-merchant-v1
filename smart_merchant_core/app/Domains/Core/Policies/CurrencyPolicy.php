<?php

namespace App\Domains\Core\Policies;

use App\Domains\Core\Models\User;
use App\Models\Core\Currency;
use Illuminate\Auth\Access\HandlesAuthorization;

class CurrencyPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Currency $currency): bool { return true; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Currency $currency): bool { return true; }
    public function delete(User $user, Currency $currency): bool { return true; }
    public function activate(User $user, Currency $currency): bool { return true; }
    public function deactivate(User $user, Currency $currency): bool { return true; }
    public function setDefault(User $user, Currency $currency): bool { return true; }
}
