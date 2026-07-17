<?php

namespace App\Domains\AccountsReceivable\Events;

use App\Domains\AccountsReceivable\Models\ReceivableEntry;

class ReceivableEntryRecorded
{
    public ReceivableEntry $entry;

    public function __construct(ReceivableEntry $entry)
    {
        $this->entry = $entry;
    }
}
