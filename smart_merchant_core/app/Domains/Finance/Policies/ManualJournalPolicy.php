<?php

namespace App\Domains\Finance\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\JournalEntry;
use Illuminate\Auth\Access\HandlesAuthorization;

class ManualJournalPolicy
{
    use HandlesAuthorization;

    public function create(User $user)
    {
        return $user->hasPermissionTo('finance.manual_journal.create');
    }

    public function view(User $user, JournalEntry $journalEntry)
    {
        return $user->hasPermissionTo('finance.manual_journal.view');
    }

    public function reverse(User $user, JournalEntry $journalEntry)
    {
        return $user->hasPermissionTo('finance.manual_journal.reverse');
    }

    public function deleteDraft(User $user, JournalEntry $journalEntry)
    {
        return $user->hasPermissionTo('finance.manual_journal.delete');
    }
}
