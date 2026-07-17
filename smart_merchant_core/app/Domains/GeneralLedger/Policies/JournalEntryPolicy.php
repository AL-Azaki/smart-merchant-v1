<?php

namespace App\Domains\GeneralLedger\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\JournalEntry;
use Illuminate\Auth\Access\HandlesAuthorization;

class JournalEntryPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, JournalEntry $journalEntry)
    {
        return true;
    }

    public function create(User $user)
    {
        return true;
    }

    public function update(User $user, JournalEntry $journalEntry)
    {
        return $journalEntry->status === 'Draft';
    }

    public function post(User $user, JournalEntry $journalEntry)
    {
        return $journalEntry->status === 'Draft';
    }

    public function reverse(User $user, JournalEntry $journalEntry)
    {
        return $journalEntry->status === 'Posted';
    }
}
